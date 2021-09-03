provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  region = "cn-hongkong"
}

variable "zone_1" {
  default = "cn-hongkong-b"
}

variable "name" {
  default = "luigi_metabase_group"
}

######## Security group
resource "alicloud_security_group" "group" {
  name        = "sg_luigi_metabase"
  description = "Security group for luigi & metabase"
  vpc_id      = alicloud_vpc.vpc.id
}

# Luigi default service port is 8082: https://luigi.readthedocs.io/en/stable/configuration.html#configurable-options
resource "alicloud_security_group_rule" "allow_http_8082" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "8082/8082"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

# Metabase default web server port is 3000: https://www.metabase.com/docs/latest/operations-guide/customizing-jetty-webserver.html
resource "alicloud_security_group_rule" "allow_http_3000" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "3000/3000"
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

  instance_type           = "ecs.c5.xlarge" # 4core 8GB
  system_disk_category    = "cloud_ssd"
  system_disk_name        = "luigi_metabase_system_disk"
  system_disk_size        = 40
  system_disk_description = "luigi_metabase_system_disk"
  image_id                = "centos_8_3_x64_20G_alibase_20210723.vhd"
  instance_name           = "luigi_metabase"
  password                = "N1cetest" ## Please change accordingly
  instance_charge_type    = "PostPaid"
  vswitch_id              = alicloud_vswitch.vswitch_1.id
}

######## RDS PostgreSQL (Metabase backend database)
resource "alicloud_db_instance" "metabase_db" {
  engine           = "PostgreSQL"
  engine_version   = "13.0"
  instance_type    = "pg.n2.small.1"
  instance_storage = "20"
  vswitch_id       = alicloud_vswitch.vswitch_1.id
  instance_name    = "metabase_database"
  security_ips     = [alicloud_vswitch.vswitch_1.cidr_block]
}

resource "alicloud_db_database" "metabase" {
  instance_id = alicloud_db_instance.metabase_db.id
  name        = "metabase"
}

resource "alicloud_rds_account" "metabase_db_account" {
  db_instance_id   = alicloud_db_instance.metabase_db.id
  account_name     = "metabase"
  account_password = "N1cetest"
  account_type     = "Super"
}

resource "alicloud_db_account_privilege" "metabase_db_privilege" {
  instance_id  = alicloud_db_instance.metabase_db.id
  account_name = alicloud_rds_account.metabase_db_account.name
  privilege    = "DBOwner"
  db_names     = alicloud_db_database.metabase.*.name
}

######## RDS PostgreSQL (Luigi & Metabase demo database)
resource "alicloud_db_instance" "demo_db" {
  engine           = "PostgreSQL"
  engine_version   = "13.0"
  instance_type    = "pg.n2.small.1"
  instance_storage = "20"
  vswitch_id       = alicloud_vswitch.vswitch_1.id
  instance_name    = "luigi_metabase_demo_database"
  security_ips     = [alicloud_vswitch.vswitch_1.cidr_block]
}

resource "alicloud_db_database" "sales_dw" {
  instance_id = alicloud_db_instance.demo_db.id
  name        = "sales_dw"
}

resource "alicloud_rds_account" "demo_db_account" {
  db_instance_id   = alicloud_db_instance.demo_db.id
  account_name     = "demo"
  account_password = "N1cetest"
  account_type     = "Super"
}

resource "alicloud_db_account_privilege" "demo_db_privilege" {
  instance_id  = alicloud_db_instance.demo_db.id
  account_name = alicloud_rds_account.demo_db_account.name
  privilege    = "DBOwner"
  db_names     = alicloud_db_database.sales_dw.*.name
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

######### Output: RDS PostgreSQL (Metabase backend database) Connection String
output "rds_pg_url_metabase_database" {
  value = alicloud_db_instance.metabase_db.connection_string
}

######### Output: RDS PostgreSQL (Metabase backend database) Connection Port
output "rds_pg_port_metabase_database" {
  value = alicloud_db_instance.metabase_db.port
}

######### Output: RDS PostgreSQL (Luigi & Metabase demo database) Connection String
output "rds_pg_url_demo_database" {
  value = alicloud_db_instance.demo_db.connection_string
}

######### Output: RDS PostgreSQL (Luigi & Metabase demo database) Connection Port
output "rds_pg_port_demo_database" {
  value = alicloud_db_instance.demo_db.port
}
