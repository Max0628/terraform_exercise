
# main.tf 僅作為 network 資源的入口，實際資源已拆分到 vpc.tf、subnet.tf、igw.tf、route_table.tf。
# 這樣做有助於維護與擴充，每個檔案只負責一類資源。
