# Terraform AWS 基礎架構實作專案

## 專案結構

### 基礎架構
- **Multi-environment setup** with Terragrunt
  - `environments/dev/` - 開發環境
  - `environments/prod/` - 生產環境
- **Reusable modules**
  - `compute/` - EC2 運算資源模組
  - `network/` - VPC 網路架構模組
- **Remote State Backend**
  - `backend-setup/` - S3 + DynamoDB 狀態管理

### 練習作業（Learning & Practice）
- `exercises/01-s3-lambda-discord/` - Event-driven S3 上傳通知
- `exercises/02-vpc-endpoint/` - VPC Endpoint（Gateway & Interface）
- `exercises/03-cloudfront-s3-static/` - CloudFront CDN + 靜態網站

詳細說明請參考 [exercises/README.md](exercises/README.md)

---

## 專案說明
本專案使用 Terraform 在 AWS 東京 region 建立完整的 VPC 架構，包含：
- VPC (10.0.0.0/18)
- 兩個 Subnet（Public: 10.0.0.0/20, Private: 10.0.16.0/20）位於不同 AZ
- Internet Gateway
- NAT Gateway
- Route Tables (Public & Private)
- 兩台 EC2（各在 Public 和 Private Subnet）
- Security Groups
- SSH Key Pair

## 架構圖
請參考 diagrams/ 資料夾內架構圖。

## 檔案結構
```
terraform_exercise/
├── root/              # 主入口，整合所有 module
├── provider/          # AWS provider 設定
├── network/           # VPC、Subnet、IGW、NAT Gateway、Route Table
├── compute/           # EC2、Security Group、Key Pair
└── diagrams/          # 架構圖
```

## 使用前準備

### 1. 安裝工具
- Terraform >= 1.6.0
- AWS CLI
- SSH Key

### 2. AWS 設定
```bash
# 設定 AWS credentials
aws configure
```

### 3. 產生 SSH Key（如果還沒有）
```bash
ssh-keygen -t rsa -b 2048
# 會產生 ~/.ssh/id_rsa 和 ~/.ssh/id_rsa.pub
```

### 4. 更新你的 IP（重要！）
編輯 `root/variables.tf`，將 `my_ip` 改為你的實際 public IP：
```bash
# 查詢你的 public IP
curl ifconfig.me

# 修改 root/variables.tf
variable "my_ip" {
  default = "你的IP/32"  # 例如 "123.45.67.89/32"
}
```

## 部署步驟

### 1. 初始化 Terraform
```bash
cd root/
terraform init
```

### 2. 檢查執行計畫
```bash
terraform plan
```

### 3. 部署資源
```bash
terraform apply
# 輸入 yes 確認
```

### 4. 查看輸出資訊
部署完成後，Terraform 會顯示：
- VPC ID
- Subnet ID 與 CIDR
- EC2 Public IP
- SSH 連線指令

## 作業驗證步驟

### 1. SSH 連入 Public EC2
```bash
ssh -i ~/.ssh/id_rsa ubuntu@<public_ec2_ip>
```

### 2. 驗證 nginx（在瀏覽器開啟）
```
http://<public_ec2_ip>
```
應該會看到 nginx 歡迎頁面，截圖保存。

### 3. 從 Public EC2 連入 Private EC2
```bash
# 在 Public EC2 上執行
ssh -i ~/.ssh/id_rsa ubuntu@<private_ec2_ip>
```

**注意**：需要先將你的 private key 複製到 Public EC2，或使用 SSH Agent Forwarding：
```bash
# 方法 1: SSH Agent Forwarding
ssh-add ~/.ssh/id_rsa
ssh -A -i ~/.ssh/id_rsa ubuntu@<public_ec2_ip>

# 方法 2: 複製 key 到 Public EC2（不建議）
scp -i ~/.ssh/id_rsa ~/.ssh/id_rsa ubuntu@<public_ec2_ip>:~/
```

### 4. 驗證 NAT Gateway（在 Private EC2 上）
```bash
curl google.com
# 應該會回傳 google 的 html 內容，證明可以透過 NAT Gateway 連外
```

## 清理資源

完成作業後，記得清理資源避免產生費用：
```bash
terraform destroy
# 輸入 yes 確認
```

## 費用預估
- t3.micro EC2 x 2
- NAT Gateway（約 $0.045/小時）
- Elastic IP x 1
- 網路傳輸費用

**建議**：完成作業後立即執行 `terraform destroy` 清理資源。

## 參考資料
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC 文件](https://docs.aws.amazon.com/vpc/)
- [AWS NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
