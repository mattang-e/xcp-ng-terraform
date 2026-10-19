# XCP-ng Terraform

Terraform과 Xen Orchestra Provider를 활용하여 XCP-ng 가상화 환경의 VM 프로비저닝을 자동화하는 프로젝트입니다.

실제 XCP-ng 환경에서 기존 VM Template, Network, NFS Storage를 활용하여 VM을 생성하고, CPU / Memory / Disk 등의 리소스를 Terraform 코드로 관리합니다.

## Architecture

```text
Terraform
    |
    v
Xen Orchestra Provider
    |
    v
Xen Orchestra
    |
    v
XCP-ng
    |
    +-- VM Template
    +-- Network
    +-- NFS Storage
    |
    v
Virtual Machines
```

## Features

- Xen Orchestra Provider를 통한 XCP-ng 연동
- 기존 VM Template 조회 및 활용
- 기존 Network 및 Storage Repository 조회
- Template 기반 VM 프로비저닝
- CPU / Memory / Disk 리소스 관리
- NFS SR 기반 VM Disk 구성
- Terraform Variable을 통한 VM 설정 관리
- `for_each`를 이용한 다중 VM 프로비저닝
- Terraform State 기반 리소스 관리
- 실제 인프라 수동 변경에 대한 Drift 감지
- 코드 변경을 통한 기존 VM 리소스 변경

## Project Structure

```text
.
├── data.tf
├── main.tf
├── outputs.tf
├── provider.tf
├── variables.tf
├── terraform.tfvars.example
├── .terraform.lock.hcl
├── .gitignore
└── README.md
```

### File Description

| File | Description |
|---|---|
| `provider.tf` | Xen Orchestra Provider 설정 |
| `data.tf` | 기존 Template, Network, Storage 조회 |
| `main.tf` | XCP-ng VM Resource 정의 |
| `variables.tf` | VM 설정에 사용할 Variable 정의 |
| `outputs.tf` | Terraform 실행 결과 출력 |
| `terraform.tfvars.example` | VM 설정값 예제 |
| `.terraform.lock.hcl` | Provider 버전 잠금 정보 |
| `.gitignore` | State, 실제 환경 설정 등 Git 제외 |

## Requirements

- XCP-ng
- Xen Orchestra
- Terraform
- Xen Orchestra Terraform Provider
- NFS Storage Repository

## Authentication

Xen Orchestra 접속 정보는 Terraform 코드에 직접 저장하지 않고 환경 변수로 관리합니다.

```bash
export XOA_URL="wss://<XOA_ADDRESS>"
export XOA_USER="<USERNAME>"
export XOA_PASSWORD="<PASSWORD>"
```

실제 인증 정보와 Terraform State 파일은 Git Repository에 포함하지 않습니다.

## VM Configuration

VM별 CPU, Memory, Disk 설정은 Terraform Variable로 관리합니다.

`terraform.tfvars` 예시:

```hcl
vms = {
  "terraform-vm01" = {
    cpus      = 2
    memory_gb = 2
    disk_gb   = 20
  }

  "terraform-vm02" = {
    cpus      = 2
    memory_gb = 2
    disk_gb   = 20
  }
}
```

`for_each`를 사용하여 하나의 VM Resource 정의로 여러 VM을 생성하고 관리합니다.

```hcl
resource "xenorchestra_vm" "vm" {
  for_each = var.vms

  name_label = each.key

  template = data.xenorchestra_template.rocky.id

  cpus       = each.value.cpus
  memory_max = each.value.memory_gb * 1024 * 1024 * 1024

  network {
    network_id = data.xenorchestra_network.network.id
  }

  disk {
    sr_id      = data.xenorchestra_sr.storage.id
    name_label = "${each.key}-disk"
    size       = each.value.disk_gb * 1024 * 1024 * 1024
  }
}
```

## Terraform Workflow

Terraform 초기화:

```bash
terraform init
```

Configuration 문법 및 설정 검증:

```bash
terraform validate
```

Terraform이 실제 인프라에 적용할 변경사항 확인:

```bash
terraform plan
```

변경사항 적용:

```bash
terraform apply
```

현재 Terraform이 관리하고 있는 Resource 확인:

```bash
terraform state list
```

## Resource Management

Terraform Configuration과 실제 XCP-ng 환경의 상태를 비교하여 변경사항을 관리합니다.

예를 들어 Terraform에서 VM CPU를 다음과 같이 정의한 경우:

```hcl
cpus = 2
```

Xen Orchestra에서 CPU를 수동으로 변경하면 `terraform plan` 실행 시 실제 인프라와 Terraform Configuration 간의 차이를 감지할 수 있습니다.

```text
Terraform Configuration
CPU = 2

        ↓ terraform plan

Actual Infrastructure
CPU = 4

        ↓ Drift Detection

Terraform Plan
CPU 4 -> 2
```

`terraform apply`를 실행하면 Terraform Configuration에 정의된 상태로 다시 변경할 수 있습니다.

## Terraform State

Terraform State는 Terraform Resource와 실제 XCP-ng Resource 간의 연결 정보를 관리합니다.

예:

```text
xenorchestra_vm.vm["terraform-vm01"]
xenorchestra_vm.vm["terraform-vm02"]
```

기존 Resource 구조를 `for_each` 방식으로 변경할 때 실제 VM을 재생성하지 않고 State 주소를 변경하여 기존 Resource를 유지할 수 있습니다.

예:

```bash
terraform state mv \
'xenorchestra_vm.vm01' \
'xenorchestra_vm.vm["terraform-vm01"]'
```

## Storage

VM Disk는 XCP-ng에 등록된 NFS Storage Repository를 사용합니다.

Terraform에서는 기존 Storage Repository를 Data Source로 조회하여 VM Disk 생성 시 사용합니다.

```hcl
data "xenorchestra_sr" "storage" {
  name_label = "<NFS_SR_NAME>"
}
```

VM Disk:

```hcl
disk {
  sr_id      = data.xenorchestra_sr.storage.id
  name_label = "${each.key}-disk"
  size       = each.value.disk_gb * 1024 * 1024 * 1024
}
```

## Security

실제 환경정보 및 Terraform State는 Git에서 제외합니다.

`.gitignore`:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
*.tfvars.json

.DS_Store
```

다음 파일들은 Repository에 포함하지 않습니다.

```text
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
.terraform/
```

반면 Provider 버전의 일관성을 유지하기 위한 `.terraform.lock.hcl` 파일은 Repository에서 관리합니다.

## Future Improvements

- VM Module 구성
- Terraform Lifecycle 설정
- 기존 XCP-ng Resource Import
- VM별 Network 설정 확장
- Terraform Output을 활용한 VM 정보 관리
- Ansible 연동을 통한 VM OS Configuration 자동화