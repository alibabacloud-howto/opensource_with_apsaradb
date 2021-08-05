provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  region = "ap-southeast-1"
}

variable "zone_1" {
  default = "ap-southeast-1b"
}

variable "name" {
  default = "netflix_dispatch_group"
}

######## Security group
resource "alicloud_security_group" "group" {
  name        = "sg_netflix_dispatch"
  description = "Security group for netflix dispatch"
  vpc_id      = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_http_80" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_http_8000" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "8000/8000"
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

  # series III
  instance_type           = "ecs.c5.large" # 2core 4GB
  system_disk_category    = "cloud_ssd"
  system_disk_name        = "netflix_dispatch_system_disk"
  system_disk_size        = 40
  system_disk_description = "netflix_dispatch_system_disk"
  image_id                = "centos_8_3_x64_20G_alibase_20210521.vhd"
  instance_name           = "netflix_dispatch"
  password                = "N1cetest" ## Please change accordingly
  instance_charge_type    = "PostPaid"
  vswitch_id              = alicloud_vswitch.vswitch_1.id
  data_disks {
    name        = "disk2"
    size        = 100
    category    = "cloud_efficiency"
    description = "disk2"
  }
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

######## RDS PostgreSQL
resource "alicloud_db_instance" "instance" {
  engine           = "PostgreSQL"
  engine_version   = "12.0"
  instance_type    = "pg.n2.small.1"
  instance_storage = "20"
  vswitch_id       = alicloud_vswitch.vswitch_1.id
  instance_name    = "netflix_dispatch_database"
  security_ips     = [alicloud_vswitch.vswitch_1.cidr_block]
}

resource "alicloud_db_database" "default" {
  instance_id = alicloud_db_instance.instance.id
  name        = "dispatch"
}

resource "alicloud_rds_account" "account" {
  db_instance_id   = alicloud_db_instance.instance.id
  account_name     = "dispatch"
  account_password = "dispatch"
  account_type     = "Super"
}

resource "alicloud_db_account_privilege" "privilege" {
  instance_id  = alicloud_db_instance.instance.id
  account_name = alicloud_rds_account.account.name
  privilege    = "DBOwner"
  db_names     = alicloud_db_database.default.*.name
}

######### Output: EIP of ECS
output "eip_ecs" {
  value = alicloud_eip.setup_ecs_access.ip_address
}

######### Output: RDS PostgreSQL Connection String
output "rds_pg_url" {
  value = alicloud_db_instance.instance.connection_string
}

######### Output: RDS PostgreSQL Connection Port
output "rds_pg_port" {
  value = alicloud_db_instance.instance.port
}
