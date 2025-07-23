# AWS Managed Microsoft AD with FSx for Windows

AWS Managed Microsoft AD와 FSx for Windows File Server, 외부 DNS 서버를 통합한 완전한 인프라를 구성하는 Terraform 코드입니다.

## 아키텍처

- **VPC**: 2개 가용영역의 퍼블릭/프라이빗 서브넷
- **AWS Managed Microsoft AD**: Standard 에디션 디렉토리 서비스
- **FSx for Windows**: AD 통합 파일 시스템
- **도메인 조인 EC2**: 퍼블릭 서브넷의 Windows Server 2022
- **외부 DNS 서버**: BIND9 기반 DNS 서버 (example.local 도메인)
- **DNS 조건부 전달자**: AD에서 외부 DNS로 포워딩

## 빠른 시작

1. **설정 파일 준비**
```bash
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars에서 ad_admin_password 수정 필수
```

2. **배포**
```bash
terraform init
terraform plan
terraform apply
```

3. **접속 정보**
- **RDP 접속**: `terraform output ec2_public_ip`
- **DNS 서버**: `terraform output dns_server_public_ip`
- **FSx 접속**: `\\<fsx_dns_name>\share`

## 주요 기능

### DNS 조건부 전달자
외부 DNS 서버로 특정 도메인 포워딩:
```hcl
ad_dns_forwarders = [
  {
    domain_name = "example.local"
    dns_ips     = ["10.0.102.150"]  # DNS 서버 IP
  }
]
```

### 외부 DNS 서버
- **도메인**: example.local
- **기본 레코드**: test.example.local, web.example.local, app.example.local
- **포워더**: 8.8.8.8, 8.8.4.4

## DNS 테스트

도메인 조인된 EC2에서:
```powershell
# AD DNS 캐시 초기화
Clear-DnsClientCache

# 외부 도메인 조회 테스트
nslookup test.example.local
```

## 파일 구조

```
├── main.tf                    # 메인 설정
├── variables.tf               # 변수 정의
├── outputs.tf                 # 출력 값
├── terraform.tfvars.example   # 설정 예시
└── modules/
    ├── networking/            # VPC 설정
    ├── active-directory/      # Managed AD 설정
    ├── fsx/                   # FSx 설정
    ├── ec2/                   # Windows EC2 설정
    └── dns-server/            # BIND9 DNS 서버
```

## 예상 비용 (ap-northeast-2)

- Managed AD Standard: ~$146/월
- FSx 300GB/32MB/s: ~$150/월  
- EC2 t3.medium (Windows): ~$35/월
- DNS 서버 t3.micro: ~$8/월
- VPC/NAT Gateway: ~$45/월
- **총 예상: ~$384/월**

## 정리

```bash
terraform destroy
```

## 문제 해결

### DNS 캐시 문제
AWS Managed AD는 관리형 서비스라서 DNS 캐시를 직접 초기화할 수 없습니다:

**해결 방법:**
1. 조건부 전달자 재설정
2. TTL 값 조정 (현재 24시간)
3. 클라이언트 DNS 캐시 초기화: `Clear-DnsClientCache`

### RSAT (AD 관리 도구)
도메인 조인된 EC2에서 RSAT 설치:
```powershell
Install-WindowsFeature -Name RSAT-DNS-Server
Install-WindowsFeature -Name RSAT-AD-Tools
```