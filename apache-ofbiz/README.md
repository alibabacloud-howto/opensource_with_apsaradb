# Deploy and Run Apache OFBiz on Alibaba Cloud
Running open source project Apache OFBiz on Alibaba Cloud with ApsaraDB (Alibaba Cloud Database).

---
### Overview
[Apache OFBiz (https://ofbiz.apache.org/)](https://ofbiz.apache.org/) is an open source enterprise resource planning (ERP) system. It provides a suite of enterprise applications that integrate and automate many of the business processes of an enterprise.

To enhance with the database high availability behind the Apache OFBiz, we will show the steps of deployment working with Alibaba Cloud Database.
By default OFBiz includes and is configured for an embedded Java database called Derby. This is a great database for demonstration, testing, development, and even small-scale production environments. There are many databases that OFBiz can use, both commercial and open source. While there are significant production instances of OFBiz running using Oracle, MS SQL Server, and so on, we generally recommend using an open source database such as PostgreSQL or MySQL. Which database to use is an important decision and may have a future impacts on your implementation. If you do not have a preferred database choice then we strongly recommend discussing options with an experienced consultant before making a final decision.

In this tutorial, we will show the case of using [RDS MySQL](https://www.alibabacloud.com/product/apsaradb-for-rds-mysql) high availability edition to replace the Derby for more stable production purpose.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/redash-anim.gif)

Deployment architecture:

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS and database on Alibaba Cloud]()
- [Step 2. Deploy and setup OFBiz on ECS with RDS MySQL]()

---
### Step 1. Use Terraform to provision ECS and database on Alibaba Cloud

Run the [terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/redash/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use RDS MySQL as backend database of OFBiz, so ECS and RDS MySQL instances are included in the Terraform script). Please specify the necessary information and region to deploy.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/tf-parms.png)

After the Terraform script execution finished, the ECS and RDS MySQL instance information are listed as below.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/tf-done.png)

### Step 2. Deploy and setup OFBiz on ECS with RDS MySQL

Please log on to ECS with ``ECS EIP``.

```bash
ssh root@<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/ecs-logon.png)

Then execute the following commands to setup the Apache OFBiz.

```bash
mkdir /opt/redash
wget https://raw.githubusercontent.com/getredash/setup/master/setup.sh
sh setup.sh
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/setup-done.png)

After the setup script execution finished, open the following URL in a Web browser to initialize Redash: 

```bash
http://<ECS_EIP>
```








cd ofbiz-framework

vim framework/security/config/security.properties 

**host-headers-allowed** 

cp framework/entity/config/entityengine.xml framework/entity/config/entityengine_backup.xml
vim framework/entity/config/entityengine.xml

**localmysql**
jdbc-uri
jdbc-username
jdbc-password

**localmysqlolap**

**localmysqltenant**


Replace derby with mysql in **default**, **default-no-eca** and **test** delegators as follows:

localderby -> localmysql
localderbyolap -> localmysqlolap
localderbytenant -> localmysqltenant




./gradlew cleanAll loadAll


./gradlew ofbiz

https://47.241.194.101:8443/accounting
admin
ofbiz


## Stop: 
./gradlew 'ofbiz --shutdown'
