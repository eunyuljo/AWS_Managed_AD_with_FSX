# AWS Managed Microsoft AD with FSx for Windows

AWS Managed Microsoft AD와 FSx for Windows File Server를 통합한 완전한 인프라 구성을 위한 Terraform 설정입니다. 
모듈화된 구조로 구성되어 있습니다.

## 아키텍처

- **VPC**: 2개 가용영역에 걸쳐 퍼블릭/프라이빗 서브넷을 가진 커스텀 VPC  
- **AWS Managed Microsoft AD**: Standard 에디션 디렉토리 서비스
- **FSx for Windows**: Managed AD와 통합된 파일 시스템
- **EC2 인스턴스**: 퍼블릭 서브넷의 도메인 조인 Windows Server 2022 (인터넷 접근 가능)
- **보안 그룹**: AD, FSx, EC2 통신을 위해 적절히 구성된 보안 그룹

## 사전 요구사항

- Terraform >= 1.5
- 적절한 권한으로 구성된 AWS CLI
- AWS Provider >= 5.0

## 사용 방법

1. `terraform.tfvars.example`을 `terraform.tfvars`로 복사
2. `terraform.tfvars` 파일을 편집하여 설정값 변경 (특히 `ad_admin_password`)
3. Terraform 명령어 실행:

```bash
terraform init
terraform plan
terraform apply
```

## 파일 구조

```
├── main.tf                    # 모듈을 사용하는 메인 설정 파일
├── variables.tf               # 입력 변수 정의  
├── outputs.tf                 # 출력 값 정의
├── terraform.tfvars.example   # 예시 변수 값들
└── modules/
    ├── networking/            # VPC와 서브넷 설정
    ├── active-directory/      # Managed Microsoft AD 설정  
    ├── fsx/                   # FSx for Windows File Server 설정
    └── ec2/                   # 도메인 조인 EC2 인스턴스 설정
```

## 출력 결과

배포 완료 후 다음과 같은 정보를 얻을 수 있습니다:

- VPC 및 서브넷 ID들
- Managed AD 디렉토리 ID 및 DNS IP 주소들
- FSx 파일 시스템 ID 및 DNS 이름
- EC2 인스턴스 ID, 프라이빗 IP 및 퍼블릭 IP 주소
- 액세스 URL 및 네트워크 인터페이스 세부 정보

## 보안

- AD와 FSx는 프라이빗 서브넷에 배포됩니다
- EC2는 퍼블릭 서브넷에 배포되어 인터넷에서 RDP 접근 가능합니다
- 보안 그룹은 필요한 포트로만 액세스를 제한합니다
- RDP 접근은 기본적으로 전체 인터넷(0.0.0.0/0)에서 허용됩니다 (보안상 특정 IP로 제한 권장)
- AD 관리자 비밀번호는 안전하게 저장해야 합니다 (AWS Secrets Manager 고려)

## 비용 예상

예상 월 비용 (ap-northeast-2):
- Managed AD Standard: 약 $146/월
- FSx 300GB/32MB/s: 약 $150/월
- EC2 t3.medium (Windows): 약 $35/월
- VPC/NAT Gateway: 약 $45/월
- **총 예상 비용: 약 $376/월**

## 정리

```bash
terraform destroy
```

## 지원

문제나 질문이 있으시면 AWS 문서를 참조하세요:
- [AWS Managed Microsoft AD](https://docs.aws.amazon.com/directoryservice/)
- [Amazon FSx for Windows](https://docs.aws.amazon.com/fsx/)