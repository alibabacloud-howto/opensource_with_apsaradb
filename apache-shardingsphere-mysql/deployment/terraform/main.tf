provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  region = "cn-hongkong"
}

variable "zone_1" {
  default = "cn-hongkong-b"
}

variable "name" {
  default = "apache_shardingsphere_group"
}

######## Security group
resource "alicloud_security_group" "group" {
  name        = "sg_apache_shardingsphere"
  description = "Security group for apache shardingsphere"
  vpc_id      = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_http_3307" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "3307/3307"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_http_8001" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "8001/8001"
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

  instance_type           = "ecs.c5.xlarge" # 4core 8GB
  system_disk_category    = "cloud_ssd"
  system_disk_name        = "apache_shardingsphere_system_disk"
  system_disk_size        = 40
  system_disk_description = "apache_shardingsphere_system_disk"
  image_id                = "ubuntu_20_04_x64_20G_alibase_20211027.vhd"
  instance_name           = "apache_shardingsphere"
  password                = "N1cetest" ## Please change accordingly
  instance_charge_type    = "PostPaid"
  vswitch_id              = alicloud_vswitch.vswitch_1.id
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

######## RDS MySQL
resource "alicloud_db_instance" "instance_0" {
  engine           = "MySQL"
  engine_version   = "8.0"
  instance_type    = "rds.mysql.s1.small"
  instance_storage = "20"
  vswitch_id       = alicloud_vswitch.vswitch_1.id
  instance_name    = "apache_shardingsphere_instance_0"
  security_ips     = [alicloud_vswitch.vswitch_1.cidr_block]
}

resource "alicloud_db_instance" "instance_1" {
  engine           = "MySQL"
  engine_version   = "8.0"
  instance_type    = "rds.mysql.s1.small"
  instance_storage = "20"
  vswitch_id       = alicloud_vswitch.vswitch_1.id
  instance_name    = "apache_shardingsphere_instance_1"
  security_ips     = [alicloud_vswitch.vswitch_1.cidr_block]
}

resource "alicloud_db_instance" "instance_2" {
  engine           = "MySQL"
  engine_version   = "8.0"
  instance_type    = "rds.mysql.s1.small"
  instance_storage = "20"
  vswitch_id       = alicloud_vswitch.vswitch_1.id
  instance_name    = "apache_shardingsphere_instance_2"
  security_ips     = [alicloud_vswitch.vswitch_1.cidr_block]
}

resource "alicloud_db_instance" "instance_3" {
  engine           = "MySQL"
  engine_version   = "8.0"
  instance_type    = "rds.mysql.s1.small"
  instance_storage = "20"
  vswitch_id       = alicloud_vswitch.vswitch_1.id
  instance_name    = "apache_shardingsphere_instance_3"
  security_ips     = [alicloud_vswitch.vswitch_1.cidr_block]
}

resource "alicloud_rds_account" "account_0" {
  db_instance_id   = alicloud_db_instance.instance_0.id
  account_name     = "r1"
  account_password = "N1cetest"
  account_type     = "Super"
}

resource "alicloud_rds_account" "account_1" {
  db_instance_id   = alicloud_db_instance.instance_1.id
  account_name     = "r1"
  account_password = "N1cetest"
  account_type     = "Super"
}

resource "alicloud_rds_account" "account_2" {
  db_instance_id   = alicloud_db_instance.instance_2.id
  account_name     = "r1"
  account_password = "N1cetest"
  account_type     = "Super"
}

resource "alicloud_rds_account" "account_3" {
  db_instance_id   = alicloud_db_instance.instance_3.id
  account_name     = "r1"
  account_password = "N1cetest"
  account_type     = "Super"
}

resource "alicloud_db_database" "db0" {
  instance_id = alicloud_db_instance.instance_0.id
  name        = "db0"
}

resource "alicloud_db_database" "db1" {
  instance_id = alicloud_db_instance.instance_1.id
  name        = "db1"
}

resource "alicloud_db_database" "db2" {
  instance_id = alicloud_db_instance.instance_2.id
  name        = "db2"
}

resource "alicloud_db_database" "db3" {
  instance_id = alicloud_db_instance.instance_3.id
  name        = "db3"
}

######### Output: EIP of ECS
output "eip_ecs" {
  value = alicloud_eip.setup_ecs_access.ip_address
}

######### Output: RDS MySQL Connection String
output "rds_mysql_0_url" {
  value = alicloud_db_instance.instance_0.connection_string
}

output "rds_mysql_1_url" {
  value = alicloud_db_instance.instance_1.connection_string
}

output "rds_mysql_2_url" {
  value = alicloud_db_instance.instance_2.connection_string
}

output "rds_mysql_3_url" {
  value = alicloud_db_instance.instance_3.connection_string
}

######### Output: RDS MySQL Connection Port
output "rds_mysql_0_port" {
  value = alicloud_db_instance.instance_0.port
}

output "rds_mysql_1_port" {
  value = alicloud_db_instance.instance_1.port
}

output "rds_mysql_2_port" {
  value = alicloud_db_instance.instance_2.port
}

output "rds_mysql_3_port" {
  value = alicloud_db_instance.instance_3.port
}
