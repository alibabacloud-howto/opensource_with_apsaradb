# Deploy and Run Apache OFBiz on Alibaba Cloud with Alibaba Cloud Database
Running open source project Apache OFBiz on Alibaba Cloud with ApsaraDB (Alibaba Cloud Database).

You can access the tutorial artifact including deployment script (Terraform), related source code, sample data and instruction guidance from the github project:
[https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-ofbiz](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-ofbiz)

More tutorial around Alibaba Cloud Database, please refer to:
[https://github.com/alibabacloud-howto/database](https://github.com/alibabacloud-howto/database)

---
### Overview
[Apache OFBiz (https://ofbiz.apache.org/)](https://ofbiz.apache.org/) is an open source enterprise resource planning (ERP) system. It provides a suite of enterprise applications that integrate and automate many of the business processes of an enterprise.

To enhance with the database high availability behind the Apache OFBiz, we will show the steps of deployment working with Alibaba Cloud Database.
By default OFBiz includes and is configured for an embedded Java database called Derby. This is a great database for demonstration, testing, development, and even small-scale production environments. There are many databases that OFBiz can use, both commercial and open source. While there are significant production instances of OFBiz running using Oracle, MS SQL Server, and so on, we generally recommend using an open source database such as PostgreSQL or MySQL. Which database to use is an important decision and may have a future impacts on your implementation. If you do not have a preferred database choice then we strongly recommend discussing options with an experienced consultant before making a final decision.

In this tutorial, we will show the case of using [RDS MySQL](https://www.alibabacloud.com/product/apsaradb-for-rds-mysql) high availability edition to replace the Derby for more stable production purpose.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/ofbiz.png)

Deployment architecture:

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS and database on Alibaba Cloud](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-ofbiz#step-1-use-terraform-to-provision-ecs-and-database-on-alibaba-cloud)
- [Step 2. Deploy and setup OFBiz on ECS with RDS MySQL](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-ofbiz#step-2-deploy-and-setup-ofbiz-on-ecs-with-rds-mysql)

---
### Step 1. Use Terraform to provision ECS and database on Alibaba Cloud

Run the [terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-ofbiz/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use RDS MySQL as backend database of OFBiz, so ECS and RDS MySQL instances are included in the Terraform script). Please specify the necessary information and region to deploy.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/tf-parms.png)

After the Terraform script execution finished, the ECS and RDS MySQL instance information are listed as below.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/tf_done.png)

### Step 2. Deploy and setup OFBiz on ECS with RDS MySQL

Please log on to ECS with ``ECS EIP``.

```bash
ssh root@<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/ecs-logon.png)

Then execute the following commands to setup the Apache OFBiz.

```bash
wget https://raw.githubusercontent.com/alibabacloud-howto/opensource_with_apsaradb/main/apache-ofbiz/setup.sh
sh setup.sh
```

After the setup script execution finished, go to edit the property ``host-headers-allowed`` in ``security.properties`` file to add the host IP of the ECS: 

```
cd ofbiz-framework
vim framework/security/config/security.properties 
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/config_host.png)

Then edit the ``entityengine_backup.xml`` configuration file to set the backend database as RDS MySQL to replace the Derby. Edit with the RDS MySQL connection string and database accounts as shown in the following pictures.

```
cp framework/entity/config/entityengine.xml framework/entity/config/entityengine_backup.xml
vim framework/entity/config/entityengine.xml
```
![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/mysql_jdbc_config_1.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/mysql_jdbc_config_2.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/mysql_jdbc_config_3.png)

Replace Derby with RDS MySQL in ``default``, ``default-no-eca`` and ``test`` delegators as follows:

- ``localderby`` -> ``localmysql``
- ``localderbyolap`` -> ``localmysqlolap``
- ``localderbytenant`` -> ``localmysqltenant``

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/datasource-config.png)

Execute the following command to build and initialize the OFBiz.

```
./gradlew cleanAll loadAll
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/build_ok.png)

Execute the following command to start the OFBiz.

```
./gradlew ofbiz
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/start_ok.png)

OFBiz now started. Please visit the following URL to visit the OFBiz now.

```
https://<ECS_EIP>:8443/accounting
```

By default, the administrator account name is ``admin``, password is ``ofbiz``.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/ofbiz_logon.png)