# compute/main.tf 僅作為 compute 資源的入口
# 實際資源已拆分到 security_group.tf、keypair.tf、ec2.tf
# 這樣做有助於維護與擴充，每個檔案只負責一類資源。
