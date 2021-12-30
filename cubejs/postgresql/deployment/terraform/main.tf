provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  region = "cn-hongkong"
}

variable "zone_1" {
  default = "cn-hongkong-b"
}

variable "name" {
  default = "nodejs_app_group"
}

######## Security group
resource "alicloud_security_group" "group" {
  name        = "sg_nodejs_app_app"
  description = "Security group for Node.js app"
  vpc_id      = alicloud_vpc.vpc.id
}

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

resource "alicloud_security_group_rule" "allow_http_3001" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "3001/3001"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_http_4000" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "4000/4000"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_http_8080" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "8080/8080"
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

  instance_type           = "ecs.c5.xlarge"
  system_disk_category    = "cloud_ssd"
  system_disk_name        = "nodejs_app_system_disk"
  system_disk_size        = 40
  system_disk_description = "nodejs_app_system_disk"
  image_id                = "ubuntu_20_04_x64_20G_alibase_20211123.vhd"
  instance_name           = "nodejs_app"
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

######## RDS PostgreSQL
resource "alicloud_db_instance" "instance" {
  engine           = "PostgreSQL"
  engine_version   = "14.0"
  instance_type    = "pg.n2.medium.1"
  instance_storage = "20"
  vswitch_id       = alicloud_vswitch.vswitch_1.id
  instance_name    = "cubejs_database"
  security_ips     = [alicloud_vswitch.vswitch_1.cidr_block]
}

resource "alicloud_db_database" "default" {
  instance_id = alicloud_db_instance.instance.id
  name        = "ecom"
}

resource "alicloud_rds_account" "account" {
  db_instance_id   = alicloud_db_instance.instance.id
  account_name     = "cubejs"
  account_password = "N1cetest"
  account_type     = "Super"
}

resource "alicloud_db_account_privilege" "privilege" {
  instance_id  = alicloud_db_instance.instance.id
  account_name = alicloud_rds_account.account.name
  privilege    = "DBOwner"
  db_names     = alicloud_db_database.default.*.name
}

resource "null_resource" "init" {
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt-get update",
      "sudo apt install npm -y",
      "sudo apt install docker.io -y",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose",
      "sudo apt install nodejs npm -y",
      "sudo apt install git -y",
      "wget http://cube.dev/downloads/ecom-dump.sql",
      "git clone https://github.com/cube-js/cube.js.git",
      "cd ~/cube.js/examples/react-dashboard",
      "wget https://raw.githubusercontent.com/alibabacloud-howto/opensource_with_apsaradb/main/cubejs/postgresql/docker-compose.yml",
      "sudo apt install postgresql-client-common -y",
      "sudo apt install postgresql-client -y",
      "PGPASSWORD=${alicloud_rds_account.account.account_password} psql -h${alicloud_db_instance.instance.connection_string} -U${alicloud_rds_account.account.account_name} ${alicloud_db_database.default.name} -f ~/ecom-dump.sql",
    ]

    connection {
      type     = "ssh"
      user     = "root"
      password = alicloud_instance.instance.password
      host     = alicloud_eip.setup_ecs_access.ip_address
    }
  }
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
