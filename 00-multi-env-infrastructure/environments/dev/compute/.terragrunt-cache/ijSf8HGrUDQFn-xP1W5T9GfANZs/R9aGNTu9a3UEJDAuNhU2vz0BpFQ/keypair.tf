# -------- SSH Key Pair --------
# 建立 EC2 用的 SSH Key Pair
# 請確保你本機有 ~/.ssh/id_rsa.pub 這個檔案
# 若沒有，請執行 ssh-keygen -t rsa -b 2048 產生
resource "aws_key_pair" "main" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub")

  tags = {
    Name = var.key_name
  }
}
