provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  region = "cn-hongkong"
}

variable "zone_1" {
  default = "cn-hongkong-b"
}

variable "name" {
  default = "e_commerce_group"
}

######## Security group
resource "alicloud_security_group" "group" {
  name        = "sg_e_commerce_app"
  description = "Security group for e-commerce app"
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

  instance_type           = "ecs.c5.xlarge" # 4core 8GB
  system_disk_category    = "cloud_ssd"
  system_disk_name        = "e_commerce_app_system_disk"
  system_disk_size        = 40
  system_disk_description = "e_commerce_app_system_disk"
  image_id                = "centos_8_4_x64_20G_alibase_20210824.vhd"
  instance_name           = "e_commerce_app"
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

######### Output: EIP of ECS
output "eip_ecs" {
  value = alicloud_eip.setup_ecs_access.ip_address
}
