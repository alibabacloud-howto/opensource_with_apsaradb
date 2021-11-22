# Deploy Sharding Service with Apache ShardingSphere on RDS for PostgreSQL

You can access the tutorial artifact including deployment script (Terraform), related source code, sample data and instruction guidance from the github project:
https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-shardingsphere-postgresql

More tutorial around Alibaba Cloud Database, please refer to:
[https://github.com/alibabacloud-howto/database](https://github.com/alibabacloud-howto/database)

---
### Overview

[Apache ShardingSphere](https://shardingsphere.apache.org/) is an open-source ecosystem consisted of a set of distributed database solutions, including 3 independent products, JDBC, Proxy & Sidecar (Planning). They all provide functions of data scale out, distributed transaction and distributed governance, applicable in a variety of situations such as Java isomorphism, heterogeneous language and cloud native.

In this solution tutorial, let's see how to deploy sharding service with [Apache ShardingSphere Proxy](https://shardingsphere.apache.org/document/current/en/quick-start/shardingsphere-proxy-quick-start/) on [RDS for PostgreSQL](https://www.alibabacloud.com/product/apsaradb-for-rds-postgresql) on Alibaba Cloud.

ShardingSphere proxy logical diagram:

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-shardingsphere-postgresql/images/shardingsphere-proxy_v2.png)

Deployment architecture of this tutorial:

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-shardingsphere-postgresql/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS and RDS for PostgreSQL database on Alibaba Cloud]()
- [Step 2. Install and deploy ShardingSphere proxy on ECS]()
- [Step 3. Verify the deployment and sharding service]()

---
### Step 1. Use Terraform to provision ECS and RDS for PostgreSQL database on Alibaba Cloud

If you are the 1st time to use Terraform, please refer to [https://github.com/alibabacloud-howto/terraform-templates](https://github.com/alibabacloud-howto/terraform-templates) to learn how to install and use the Terraform on different operating systems.

Run the [terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-shardingsphere-postgresql/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use 4 RDS for PostgreSQL instances as the physical databases under the sharding service layer, so ECS and RDS for PostgreSQL are included in the Terraform script). Please specify the necessary information and region to deploy.

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/tf-parms.png)

After the Terraform script execution finished, the ECS instance and RDS for PostgreSQL information are listed as below.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-shardingsphere-postgresql/images/tf-done.png)

- ``eip_ecs``: The public EIP of the ECS for parse server host
- ``rds_pg_0_port``: The RDS for PostgreSQL database instance 0 service port
- ``rds_pg_0_url``: The RDS for PostgreSQL database instance 0 connection URL
- ``rds_pg_1_port``: The RDS for PostgreSQL database instance 1 service port
- ``rds_pg_1_url``: The RDS for PostgreSQL database instance 1 connection URL
- ``rds_pg_2_port``: The RDS for PostgreSQL database instance 2 service port
- ``rds_pg_2_url``: The RDS for PostgreSQL database instance 2 connection URL
- ``rds_pg_3_port``: The RDS for PostgreSQL database instance 3 service port
- ``rds_pg_3_url``: The RDS for PostgreSQL database instance 3 connection URL

---
### Step 2. Install and deploy ShardingSphere proxy on ECS

Please log on to ECS with ``ECS EIP``. By default, the password is ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/ecs-logon.png)

Execute the following commands to install Java 8, PostgreSQL client, etc.

```bash
apt update && apt -y install openjdk-8-jdk
apt update && apt -y install postgresql-client
sudo apt-get install postgresql-contrib
```

Execute the following commands to download and unzip the ShardingSphere proxy. In this tutorial, I am using the ``apache-shardingsphere-5.0.0``.

```bash
cd ~
wget https://dlcdn.apache.org/shardingsphere/5.0.0/apache-shardingsphere-5.0.0-shardingsphere-proxy-bin.tar.gz
tar -xzvf apache-shardingsphere-5.0.0-shardingsphere-proxy-bin.tar.gz
```


cd ~/apache-shardingsphere-5.0.0-shardingsphere-proxy-bin/conf
mv server.yaml server.yaml_backup
mv config-sharding.yaml config-sharding.yaml_backup

cd apache-shardingsphere-5.0.0-shardingsphere-proxy-bin/bin
./start.sh 8001

less ~/apache-shardingsphere-5.0.0-shardingsphere-proxy-bin/logs/stdout.log 

---
### Step 3. Verify the deployment and sharding service




psql -h 127.0.0.1 -p 8001 -U r1 sharding_db

create table t_order(order_id int8 primary key, user_id int8, info text, c1 int, crt_time timestamp);  
create table t_order_item(order_item_id int8 primary key, order_id int8, user_id int8, info text, c1 int, c2 int, c3 int, c4 int, c5 int, crt_time timestamp);


insert into t_order (user_id, info, c1, crt_time) values (0,'a',1,now());  
insert into t_order (user_id, info, c1, crt_time) values (1,'b',2,now());  
insert into t_order (user_id, info, c1, crt_time) values (2,'c',3,now());  
insert into t_order (user_id, info, c1, crt_time) values (3,'d',4,now());
insert into t_order (user_id, info, c1, crt_time) values (4,'e',5,now());  
insert into t_order (user_id, info, c1, crt_time) values (5,'f',6,now());  
insert into t_order (user_id, info, c1, crt_time) values (6,'g',7,now());  
insert into t_order (user_id, info, c1, crt_time) values (7,'h',8,now());


select * from t_order;

select * from t_order where user_id=1;


psql -h pgm-3ns07zdnyzidnqjr168190.pg.rds.aliyuncs.com -p 5432 -U r1 db0
select tablename from pg_tables where schemaname='public';

psql -h pgm-3ns07zdnyzidnqjr168190.pg.rds.aliyuncs.com -p 5432 -U r1 db1
psql -h pgm-3ns07zdnyzidnqjr168190.pg.rds.aliyuncs.com -p 5432 -U r1 db2
psql -h pgm-3ns07zdnyzidnqjr168190.pg.rds.aliyuncs.com -p 5432 -U r1 db3