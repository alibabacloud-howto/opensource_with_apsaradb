# Deploy Sharding Service with Apache ShardingSphere Proxy on RDS for MySQL

You can access the tutorial artifact including deployment script (Terraform), related source code, sample data and instruction guidance from the github project:
https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-shardingsphere-mysql

More tutorial around Alibaba Cloud Database, please refer to:
[https://github.com/alibabacloud-howto/database](https://github.com/alibabacloud-howto/database)

---
### Overview

[Apache ShardingSphere](https://shardingsphere.apache.org/) is an open-source ecosystem consisted of a set of distributed database solutions, including 3 independent products, JDBC, Proxy & Sidecar (Planning). They all provide functions of data scale out, distributed transaction and distributed governance, applicable in a variety of situations such as Java isomorphism, heterogeneous language and cloud native.

In this solution tutorial, let's see how to deploy sharding service with [Apache ShardingSphere Proxy](https://shardingsphere.apache.org/document/current/en/quick-start/shardingsphere-proxy-quick-start/) on [RDS for MySQL](https://www.alibabacloud.com/product/apsaradb-for-rds-mysql) on Alibaba Cloud.

ShardingSphere proxy logical diagram:

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-shardingsphere-postgresql/images/shardingsphere-proxy_v2.png)

Deployment architecture of this tutorial:

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-shardingsphere-mysql/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS and RDS for MySQL database on Alibaba Cloud](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-shardingsphere-mysql#step-1-use-terraform-to-provision-ecs-and-rds-for-mysql-database-on-alibaba-cloud)
- [Step 2. Install and deploy ShardingSphere proxy on ECS](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-shardingsphere-mysql#step-2-install-and-deploy-shardingsphere-proxy-on-ecs)
- [Step 3. Verify the deployment and sharding service](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-shardingsphere-mysql#step-3-verify-the-deployment-and-sharding-service)

---
### Step 1. Use Terraform to provision ECS and RDS for MySQL database on Alibaba Cloud

If you are the 1st time to use Terraform, please refer to [https://github.com/alibabacloud-howto/terraform-templates](https://github.com/alibabacloud-howto/terraform-templates) to learn how to install and use the Terraform on different operating systems.

Run the [terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-shardingsphere-mysql/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use 4 RDS for MySQL instances as the physical databases under the sharding service layer, so ECS and RDS for MySQL are included in the Terraform script). Please specify the necessary information and region to deploy.

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/tf-parms.png)

After the Terraform script execution finished, the ECS instance and RDS for MySQL information are listed as below.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-shardingsphere-mysql/images/tf-done.png)

- ``eip_ecs``: The public EIP of the ECS for parse server host
- ``rds_mysql_0_port``: The RDS for My'SQL database instance 0 service port
- ``rds_mysql_0_url``: The RDS for MySQL database instance 0 connection URL
- ``rds_mysql_1_port``: The RDS for MySQL database instance 1 service port
- ``rds_mysql_1_url``: The RDS for MySQL database instance 1 connection URL
- ``rds_mysql_2_port``: The RDS for MySQL database instance 2 service port
- ``rds_mysql_2_url``: The RDS for MySQL database instance 2 connection URL
- ``rds_mysql_3_port``: The RDS for MySQL database instance 3 service port
- ``rds_mysql_3_url``: The RDS for MySQL database instance 3 connection URL

---
### Step 2. Install and deploy ShardingSphere proxy on ECS

Please log on to ECS with ``ECS EIP``. By default, the password is ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/ecs-logon.png)

Java 8 and MySQL client had already been installed automatically in the resource ``null_resource`` in [Terraform scrip](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-shardingsphere-mysql/deployment/terraform/main.tf) in Step 1.

Execute the following commands to download and unzip the ShardingSphere proxy. In this tutorial, I am using the ``apache-shardingsphere-5.0.0``.

```bash
cd ~
wget https://dlcdn.apache.org/shardingsphere/5.0.0/apache-shardingsphere-5.0.0-shardingsphere-proxy-bin.tar.gz
tar -xzvf apache-shardingsphere-5.0.0-shardingsphere-proxy-bin.tar.gz
```

Execute the following commands to backup the original configuration file ``server.yaml`` and ``config-sharding.yaml``.

```bash
cd ~/apache-shardingsphere-5.0.0-shardingsphere-proxy-bin/conf
mv server.yaml server.yaml_backup
mv config-sharding.yaml config-sharding.yaml_backup
```

Execute the following commands to download the MySQL JDBC driver and deploy to the ShardingSphere proxy library.

```bash
cd ~/apache-shardingsphere-5.0.0-shardingsphere-proxy-bin/lib
wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.11/mysql-connector-java-8.0.11.jar
```

Download the ``server.yaml`` and ``config-sharding.yaml`` from this tutorial github project. I've predefined the sharding mapping logic and all related routing configuration in the ``config-sharding.yaml``. For details, please check carefully with this file.

```bash
cd ~/apache-shardingsphere-5.0.0-shardingsphere-proxy-bin/conf
wget https://raw.githubusercontent.com/alibabacloud-howto/opensource_with_apsaradb/main/apache-shardingsphere-mysql/server.yaml
wget https://raw.githubusercontent.com/alibabacloud-howto/opensource_with_apsaradb/main/apache-shardingsphere-mysql/config-sharding.yaml
```

Now, edit the downloaded ``config-sharding.yaml`` with RDS for MySQL instances connection information accordingly. All 4 RDS for MySQL instances connection information are in ``Step 1``.

```bash
vim ~/apache-shardingsphere-5.0.0-shardingsphere-proxy-bin/conf/config-sharding.yaml
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-shardingsphere-mysql/images/config-sharding.png)

Now, the configuration finished, execute the following commands to start the ShardingSphere proxy. Let's use the port ``8001`` as the service port of the ShardingSphere proxy. By default, the ShardingSphere proxy uses ``3307`` as the service port.

```bash
cd ~/apache-shardingsphere-5.0.0-shardingsphere-proxy-bin/bin/
./start.sh 8001
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-shardingsphere-mysql/images/start_proxy.png)

Execute the following command to verify the proxy log. If you have see the following message ``ShardingSphere-Proxy start success``, then the proxy started successfully.

```bash
less ~/apache-shardingsphere-5.0.0-shardingsphere-proxy-bin/logs/stdout.log 
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-shardingsphere-mysql/images/start_proxy_success.png)

If you want to stop the proxy, please execute the following command.

```bash
sh ~/apache-shardingsphere-5.0.0-shardingsphere-proxy-bin/bin/stop.sh
```

---
### Step 3. Verify the deployment and sharding service

Now, let's verify the ShardingSphere proxy. Execute the commands to connect to the sharding proxy, execute the CREATE TABLE DDL commands, insert some records and verify the data.
The password used for ShardingSphere proxy is predefine as ``N1cetest`` in https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-shardingsphere-mysql/server.yaml.

```bash
mysql -h 127.0.0.1 -P 8001 -u r1 sharding_db -p
```

```bash
create table t_order(order_id bigint, user_id smallint, info text, c1 smallint, crt_time timestamp, PRIMARY KEY ( order_id ));  
create table t_order_item(order_item_id bigint, order_id smallint, user_id smallint, info text, c1 smallint, c2 smallint, c3 smallint, c4 smallint, c5 smallint, crt_time timestamp, PRIMARY KEY ( order_item_id ));

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
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-shardingsphere-mysql/images/verify-1.png)

This shows the sharding service works perfectly. And let's connect to the physical RDS for MySQL database directly to view the data records distribution in these 4 RDS for MySQL database instances.
Please remember to use the RDS for MySQL database instance connection string to replace ``<RDS_MYSQL_INSTANCE_0_URL>``, ``<RDS_MYSQL_INSTANCE_1_URL>``, ``<RDS_MYSQL_INSTANCE_2_URL>`` and ``<RDS_MYSQL_INSTANCE_3_URL>``.
The password used for RDS for MySQL database is predefine as ``N1cetest`` in https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-shardingsphere-mysql/deployment/terraform/main.tf.

```bash
mysql -h <RDS_MYSQL_INSTANCE_0_URL> -P 3306 -u r1 db0 -p

show tables;
select * from t_order_0;
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-shardingsphere-mysql/images/verify-2.png)

Similar with ``db1``, ``db2`` and ``db3``.

```bash
mysql -h <RDS_MYSQL_INSTANCE_1_URL> -P 3306 -u r1 db1 -p

show tables;
select * from t_order_1;
```

```bash
mysql -h <RDS_MYSQL_INSTANCE_2_URL> -P 3306 -u r1 db2 -p

show tables;
select * from t_order_0;
```

```bash
mysql -h <RDS_MYSQL_INSTANCE_3_URL> -P 3306 -u r1 db3 -p

show tables;
select * from t_order_1;
```

