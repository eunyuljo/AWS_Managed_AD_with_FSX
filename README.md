## 작성 배경

AWS FSx 를 사용하기 위해서는 기본적으로 AD 를 통한 연결 구성이 필요하다.
이 AD에 조인된 서버는 AD의 DNS를 참조하게 되는데, 
이 DNS는 기본적으로 Conditional Forwarding 를 설정하고 있으며, Recursive 한 동작을 지원하지 않는 관계로 실시간으로 DNS Server의 레코드를 받아오지 않는다. 
추가적인 대안을 확인하기 위한 기본 Base 인프라를 재현하기 위한 Terraform Code 이다.

추가적으로 FSx 에 대한 연결 방법도 추가적으로 별도로 확인해본다.

## 아키텍처

- **VPC**: 가용영역의 퍼블릭/프라이빗 서브넷 2개 
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
# Terraform 수행 환경에 맞는 일부 설정이 필요하다. PEM 키 설정이 필요하다.
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

위 DNS IP는 AMZN 2023 으로 생성한 bind9 서버로 해당 인스턴스의 사설 IP를 대상으로 한다.
AD 가 Forwarder로써 바라보는 외부 DNS라는 의미이다.

```

### 외부 DNS 서버
- **도메인**: example.local
- **기본 레코드**: test.example.local, web.example.local, app.example.local
- **포워더**: 8.8.8.8, 8.8.4.4

## DNS 테스트

기본 dns_server_records 에 지정된 test.example.local 이 가지고 있는 IP를 정상적으로 질의가 가능한 상태에서 시작한다.
해당 zone 파일을 수정 후 named 재시작을 하더라도 windows 에서는 즉각적으로 IP가 갱신되지 않는 것을 볼 수 있다.

도메인 조인된 EC2에서:
```powershell
# AD DNS 캐시 초기화
Clear-DnsClientCache
# Windows 에서 직접 캐시 초기화해도 어차피 AD의 DNS 에서 Cached 된 IP를 받아오므로 의미 없다.

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

**해결 방안:**
1. 조건부 전달자 재설정
2. TTL 값 조정
3. RSAT를 통해 직접 AD에 연결 후 DNS 를 초기화한다. 이 설정을 하는 경우 즉각 받아온다. 


### RSAT (AD 관리 도구) 설치 및 초기 방법
도메인 조인된 EC2에서 RSAT 설치:
```powershell
Install-WindowsFeature -Name RSAT-DNS-Server
Install-WindowsFeature -Name RSAT-AD-Tools
```

<img width="818" height="695" alt="Image" src="https://github.com/user-attachments/assets/a1ddcdc5-65b2-4a5f-a4e5-34c306af8a8f" />

