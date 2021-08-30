provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  region = "cn-hongkong"
}

variable "zone_1" {
  default = "cn-hongkong-b"
}

variable "name" {
  default = "apache_azkaban_group"
}

######## Security group
resource "alicloud_security_group" "group" {
  name        = "sg_apache_azkaban"
  description = "Security group for apache azkaban"
  vpc_id      = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_http_8081" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "8081/8081"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_http_8443" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "8443/8443"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_https_443" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "443/443"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_ssh_22" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_rdp_3389" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "3389/3389"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_all_icmp" {
  type              = "ingress"
  ip_protocol       = "icmp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

######## VPC
resource "alicloud_vpc" "vpc" {
  vpc_name   = var.name
  cidr_block = "192.168.0.0/16"
}

resource "alicloud_vswitch" "vswitch_1" {
  vpc_id       = alicloud_vpc.vpc.id
  cidr_block   = "192.168.0.0/24"
  zone_id      = var.zone_1
  vswitch_name = "vsw_on_zone_1"
}

######## ECS
resource "alicloud_instance" "instance" {
  security_groups = alicloud_security_group.group.*.id

  instance_type           = "ecs.c5.large" # 2core 4GB
  system_disk_category    = "cloud_ssd"
  system_disk_name        = "apache_azkaban_system_disk"
  system_disk_size        = 40
  system_disk_description = "apache_azkaban_system_disk"
  image_id                = "centos_8_3_x64_20G_alibase_20210723.vhd"
  instance_name           = "apache_azkaban"
  password                = "N1cetest" ## Please change accordingly
  instance_charge_type    = "PostPaid"
  vswitch_id              = alicloud_vswitch.vswitch_1.id
}

######## RDS MySQL
variable "rds_mysql_name" {
  default = "rds_mysql_azkaban"
}

resource "alicloud_db_instance" "instance" {
  engine             = "MySQL"
  engine_version     = "8.0"
  instance_type      = "rds.mysql.s2.large" // 2core 4GB memory
  instance_storage   = "20"
  vswitch_id         = alicloud_vswitch.vswitch_1.id
  security_group_ids = [alicloud_security_group.group.id]
  instance_name      = var.rds_mysql_name
}

######## DB and account: azkaban
resource "alicloud_db_account" "azkaban" {
  db_instance_id   = alicloud_db_instance.instance.id
  account_name     = "azkaban"
  account_password = "N1cetest"

}
resource "alicloud_db_database" "azkaban" {
  instance_id = alicloud_db_instance.instance.id
  name        = "azkaban"
}

resource "alicloud_db_account_privilege" "azkaban" {
  instance_id  = alicloud_db_instance.instance.id
  account_name = alicloud_db_account.azkaban.name
  privilege    = "ReadWrite"
  db_names     = alicloud_db_database.azkaban.*.name
}

######## RDS PostgreSQL (Azkaban demo database)
resource "alicloud_db_instance" "azkaban_demo_db" {
  engine           = "PostgreSQL"
  engine_version   = "13.0"
  instance_type    = "pg.n2.small.1"
  instance_storage = "20"
  vswitch_id       = alicloud_vswitch.vswitch_1.id
  instance_name    = "apache_azkaban_demo_database"
  security_ips     = [alicloud_vswitch.vswitch_1.cidr_block]
}

resource "alicloud_db_database" "azkaban_demo_db_source" {
  instance_id = alicloud_db_instance.azkaban_demo_db.id
  name        = "northwind_source"
}

resource "alicloud_db_database" "azkaban_demo_db_target" {
  instance_id = alicloud_db_instance.azkaban_demo_db.id
  name        = "northwind_target"
}

resource "alicloud_rds_account" "azkaban_demo_db_account" {
  db_instance_id   = alicloud_db_instance.azkaban_demo_db.id
  account_name     = "demo"
  account_password = "N1cetest"
  account_type     = "Super"
}

resource "alicloud_db_account_privilege" "azkaban_demo_db_privilege_1" {
  instance_id  = alicloud_db_instance.azkaban_demo_db.id
  account_name = alicloud_rds_account.azkaban_demo_db_account.name
  privilege    = "DBOwner"
  db_names     = alicloud_db_database.azkaban_demo_db_source.*.name
}

resource "alicloud_db_account_privilege" "azkaban_demo_db_privilege_2" {
  instance_id  = alicloud_db_instance.azkaban_demo_db.id
  account_name = alicloud_rds_account.azkaban_demo_db_account.name
  privilege    = "DBOwner"
  db_names     = alicloud_db_database.azkaban_demo_db_target.*.name
}

######## EIP bind to setup ECS accessing from internet
resource "alicloud_eip" "setup_ecs_access" {
  bandwidth            = "5"
  internet_charge_type = "PayByBandwidth"
}

resource "alicloud_eip_association" "eip_ecs" {
  allocation_id = alicloud_eip.setup_ecs_access.id
  instance_id   = alicloud_instance.instance.id
}

######### Output: EIP of ECS
output "eip_ecs" {
  value = alicloud_eip.setup_ecs_access.ip_address
}

######### Output: RDS MySQL Connection String
output "rds_mysql_url" {
  value = alicloud_db_instance.instance.connection_string
}

######### Output: RDS PostgreSQL (Azkaban demo database) Connection String
output "rds_pg_url_azkaban_demo_database" {
  value = alicloud_db_instance.azkaban_demo_db.connection_string
}

######### Output: RDS PostgreSQL (Azkaban demo database) Connection Port
output "rds_pg_port_azkaban_demo_database" {
  value = alicloud_db_instance.azkaban_demo_db.port
}
