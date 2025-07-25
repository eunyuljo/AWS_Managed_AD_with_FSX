## 작성 배경

1. 
추가적으로 FSx 에 대한 연결 방법을 메인으로 작성. ( FSX 관련 주석 상태 - 비용 )

2. 
AWS FSx 를 사용하기 위해서는 기본적으로 AD 를 통한 연결 구성이 필요하다.
이 AD에 조인된 서버는 AD의 DNS를 참조하게 되는데, 
AWS FSx 를 마운트해서 사용하는 서버의 경우 
위 조건에 따라 애플리케이션 통신을 위한 DNS 해석 등에 대한 영향이 AD의 DNS 속성의 영향을 받게됨을 의미한다.
해당 AD DNS는 기본적으로 Conditional Forwarding 를 동작하고 있으며, 
Recursive 한 동작을 지원하지 않는 관계로 실시간으로 DNS Server의 레코드를 받아오지 않는다. 

이는 직접 동작을 확인하고 추가적인 대안을 확인하기 위한 기본 Base 인프라를 재현하기 위한 Terraform Code 이다.


## 아키텍처

- **VPC**: 가용영역의 퍼블릭/프라이빗 서브넷 2개 
- **AWS Managed Microsoft AD**: Standard 에디션 디렉토리 서비스
- **FSx for Windows**: AD 통합 파일 시스템
- **도메인 조인 EC2**: 퍼블릭 서브넷의 Windows Server 2019
- **외부 DNS 서버**: BIND9 기반 DNS 서버 (example.local 도메인)
- **DNS 조건부 전달자**: 특정 도메인에 대해서는 AD에서 외부 DNS ( bind9 ) 로 포워딩

## 빠른 시작

1. **설정 파일 준비**
```bash

# terraform.tfvars에서 ad_admin_password 수정 필수
# Terraform 수행 환경에 맞는 일부 설정이 필요하다. PEM 키 설정이 필요하다.

cp terraform.tfvars.example terraform.tfvars

# 기본 파일에서 복사해서 각 환경에 맞춰 설정해준다.

```

2. **배포**

```bash

terraform init
terraform plan
terraform apply
```

3. **접속 정보**
- **RDP 접속**: `terraform output ec2_public_ip`, `ad_domain_name\ec2_domain_admin_username`, `ad_admin_password`
- **DNS 서버**: `terraform output dns_server_public_ip`
- **FSx 접속**: `\\<fsx_dns_name>\share`


```bash
  1. 배포 후 windows 접속 방법: 
    AD 에 조인된 윈도우에는 가입된 디렉터리 DNS 이름을 기준으로 접근한다.
	  User: corp.example.com\Admin
	  Password : 위 tfvars 파일 내 암호 참고

  2. 인스턴스의 DNS 주소를 확인하여 Directory Service 에 반영된 DNS Server와 일치하는지 비교한다.
```



## 주요 기능 및 이해

### DNS 조건부 전달자
외부 DNS 서버로 특정 도메인 포워딩:
```hcl
위 DNS IP는 AMZN 2023 으로 생성한 bind9 서버로 해당 인스턴스의 사설 IP를 대상으로 한다.
AD 가 Forwarder로써 바라보는 외부 DNS 를 의미한다.
```

### 외부 DNS ( named ) 서버 및 테스트 레코드 
- **도메인**: example.local
- **기본 레코드**: test.example.local, web.example.local, app.example.local
- **포워더**: dns-server private ip 

## 기본 DNS 테스트

기본 dns_server_records 에 지정된 test.example.local 이 가지고 있는 IP를 정상적으로 질의가 가능한 상태에서 시작한다.

도메인 조인된 EC2에서:
```powershell

# 외부 도메인 조회 테스트 
nslookup test.example.local

# 사전 정의된 record 로 현재 반영된 레코드는 기본 10.0.1.100 반환받으면 준비 완료
  {
    name  = "test"
    type  = "A"
    value = "10.0.1.100"
  },
```

dns-server 에서도 zone 파일을 직접 수정하여 test.example.local 의 레코드를 변경 후 재시작하여 반영해줘도 windows 에서는 업데이트된 레코드를 즉각 받아오지 않는다.<\n>
이는 AD 내 DNS 설정인 Conditional Forwarding 설정에 의해 TTL 값을 기본적으로 가지고 있어 이 캐시된 값을 반환해주기 때문이다.
이 과정에서 애플리케이션 요청에 있어서 통신 불량이 발생한다.

---

## 이슈 해결 방법

### RSAT (AD 관리 도구) 설치 및 접속

도메인 조인된 EC2에서 RSAT 설치:
```powershell
Install-WindowsFeature -Name RSAT-DNS-Server
Install-WindowsFeature -Name RSAT-AD-Tools

# 설정 후 dns manager 접속하여 connect dns server에 dns ip로 연결한다.

dnsmgmt.msc

```

1. Clear Cache

<img width="947" height="669" alt="Image" src="https://github.com/user-attachments/assets/e617f100-b401-4289-8cb8-f5c4f843f428" />


<img width="818" height="695" alt="Image" src="https://github.com/user-attachments/assets/a1ddcdc5-65b2-4a5f-a4e5-34c306af8a8f" />


캐시를 클리어해보면 정상적으로 질의되는 것을 볼 수 있다.



2. TTL 값 0 으로 설정

```bash
# 10.0.1.133 -> Directory Service 에서 확인 가능한 DNS IP
Get-DnsServerCache -ComputerName "10.0.1.133"
```
<img width="654" height="390" alt="Image" src="https://github.com/user-attachments/assets/74e0b7c0-0af6-4d58-af07-8a6d9f888ccb" />


명령을 통해 확인해보면 MAXTTL 은 1시간, MaxNegativeTTL은 15분이다.
각각의 DNS 설정에 다음과 같이 Cache 를 0으로 초기해준다.

```bash
Set-DnsServerCache -MaxTTL 00:00:00 -ComputerName "10.0.1.133"
Set-DnsServerCache -MaxNegativeTTL 00:00:00 -ComputerName "10.0.1.133"
```

해당 설정 후 DNS Server 에서 레코드를 변경한 후 Client 에서 nslookup 을 수행해보면 바로 업데이트된 레코드가 반환되는 것을 볼 수 있다.


---

## 요약

1. 조건부 전달자 재설정
2. TTL 값 조정
3. RSAT를 통해 직접 AD에 연결 후 DNS 를 초기화하거나, Cache TTL를 0으로 설정한다. 이 설정을 하는 경우 즉각 받아온다. 

```
# AWS Managed AD가 DNS 쿼리를 받으면:

1. 내가 권한을 가진 존인가? (corp.example.com)
   → YES: 직접 응답
   → NO: 2단계로

2. 조건부 포워더가 설정된 도메인인가? (partner.com → 192.168.1.100)
   → YES: 해당 DNS 서버로 포워딩
   → NO: 3단계로

3. 기본 포워더로 전송 (VPC+2 → 8.8.8.8)
```


## 예상 비용 (ap-northeast-2)

- Managed AD Standard: ~$146/월
- FSx 300GB/32MB/s: ~$150/월  
- EC2 t3.medium (Windows): ~$35/월
- DNS 서버 t3.micro: ~$8/월
- VPC/NAT Gateway: ~$45/월
- **총 예상: ~$384/월**


## 리소스 정리

```bash
terraform destroy
```