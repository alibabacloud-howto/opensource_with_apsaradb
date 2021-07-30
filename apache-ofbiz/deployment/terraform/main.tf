provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  region = "ap-southeast-1"
}

variable "zone_1" {
  default = "ap-southeast-1b"
}

variable "name" {
  default = "apache_ofbiz_group"
}

######## Security group
resource "alicloud_security_group" "group" {
  name        = "sg_apache_ofbiz"
  description = "Security group for apache ofbiz"
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
  system_disk_name        = "apache_ofbiz_system_disk"
  system_disk_size        = 40
  system_disk_description = "apache_ofbiz_system_disk"
  image_id                = "centos_8_3_x64_20G_alibase_20210521.vhd"
  instance_name           = "apache_ofbiz"
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

######## EIP bind to wordpress setup ECS accessing from internet
resource "alicloud_eip" "setup_ecs_access" {
  bandwidth            = "5"
  internet_charge_type = "PayByBandwidth"
}

resource "alicloud_eip_association" "eip_ecs" {
  allocation_id = alicloud_eip.setup_ecs_access.id
  instance_id   = alicloud_instance.instance.id
}

######## RDS MySQL
variable "rds_mysql_name" {
  default = "rds_mysql_ofbiz"
}

resource "alicloud_db_instance" "instance" {
  engine             = "MySQL"
  engine_version     = "5.7"
  instance_type      = "rds.mysql.s2.large"
  instance_storage   = "20"
  vswitch_id         = alicloud_vswitch.vswitch_1.id
  security_group_ids = [alicloud_security_group.group.id]
  instance_name      = var.rds_mysql_name
}

######## DB and account: ofbiz
resource "alicloud_db_account" "ofbiz" {
  db_instance_id   = alicloud_db_instance.instance.id
  account_name     = "ofbiz"
  account_password = "N1cetest"
}

resource "alicloud_db_database" "ofbiz" {
  instance_id = alicloud_db_instance.instance.id
  name        = "ofbiz"
}

resource "alicloud_db_account_privilege" "ofbiz" {
  instance_id  = alicloud_db_instance.instance.id
  account_name = alicloud_db_account.ofbiz.name
  privilege    = "ReadWrite"
  db_names     = alicloud_db_database.ofbiz.*.name
}

######## DB and account: ofbizolap
resource "alicloud_db_account" "ofbizolap" {
  db_instance_id   = alicloud_db_instance.instance.id
  account_name     = "ofbizolap"
  account_password = "N1cetest"
}

resource "alicloud_db_database" "ofbizolap" {
  instance_id = alicloud_db_instance.instance.id
  name        = "ofbizolap"
}

resource "alicloud_db_account_privilege" "ofbizolap" {
  instance_id  = alicloud_db_instance.instance.id
  account_name = alicloud_db_account.ofbizolap.name
  privilege    = "ReadWrite"
  db_names     = alicloud_db_database.ofbizolap.*.name
}

######## DB and account: ofbiztenant
resource "alicloud_db_account" "ofbiztenant" {
  db_instance_id   = alicloud_db_instance.instance.id
  account_name     = "ofbiztenant"
  account_password = "N1cetest"
}

resource "alicloud_db_database" "ofbiztenant" {
  instance_id = alicloud_db_instance.instance.id
  name        = "ofbiztenant"
}

resource "alicloud_db_account_privilege" "ofbiztenant" {
  instance_id  = alicloud_db_instance.instance.id
  account_name = alicloud_db_account.ofbiztenant.name
  privilege    = "ReadWrite"
  db_names     = alicloud_db_database.ofbiztenant.*.name
}

######### Output: EIP of ECS
output "eip_ecs" {
  value = alicloud_eip.setup_ecs_access.ip_address
}

######### Output: RDS MySQL Connection String
output "rds_mysql_url" {
  value = alicloud_db_instance.instance.connection_string
}
