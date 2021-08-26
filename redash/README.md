# Deploy and Run Redash on Alibaba Cloud with Alibaba Cloud Database
Running open source project Redash on Alibaba Cloud with ApsaraDB (Alibaba Cloud Database).

You can access the tutorial artifact including deployment script (Terraform), related source code, sample data and instruction guidance from the github project:
[https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/redash](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/redash)

More tutorial around Alibaba Cloud Database, please refer to:
[https://github.com/alibabacloud-howto/database](https://github.com/alibabacloud-howto/database)

---
### Overview
[Redash (https://redash.io/)](https://redash.io/) is designed to enable anyone, regardless of the level of technical sophistication, to harness the power of data big and small. SQL users leverage Redash to explore, query, visualize, and share data from any data sources. Their work in turn enables anybody in their organization to use the data. Every day, millions of users at thousands of organizations around the world use Redash to develop insights and make data-driven decisions.
To enhance with the database high availability behind the Redash data exploration and visualization, we will show the steps of deployment working with Alibaba Cloud Database Family.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/redash-anim.gif)

In this tutorial, we will use the official [Setup](https://github.com/getredash/setup) script to deploy Redash with Docker on Ubuntu on Alibaba Cloud ECS.

Deployment architecture:

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS image and database on Alibaba Cloud](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/redash#step-1-use-terraform-to-provision-ecs-image-and-database-on-alibaba-cloud)
- [Step 2. Deploy and setup Redash on ECS](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/redash#step-2-deploy-and-setup-redash-on-ecs)
- [Step 3. Setup connection to RDS PostgreSQL](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/redash#step-3-setup-connection-to-rds-postgresql)

---
### Step 1. Use Terraform to provision ECS image and database on Alibaba Cloud

Run the [terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/redash/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use RDS PostgreSQL as example data source for Redash, so ECS and RDS PostgreSQL instances are included in the Terraform script). Please specify the necessary information and region to deploy.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/tf-parms.png)

After the Terraform script execution finished, the ECS and RDS PostgreSQL instance information are listed as below.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/tf-done.png)

### Step 2. Deploy and setup Redash on ECS

Please log on to ECS with ``ECS EIP``.

```bash
ssh root@<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/ecs-logon.png)

Then execute the following commands to setup the Redash.

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

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/redash-logon.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/redash-main.png)

---
### Step 3. Setup connection to RDS PostgreSQL

On the Redash main page, click ``Connect a data source`` to add RDS PostgreSQL as a source database.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/redash-create-1.png)

Input the RDS PostgreSQL instance connection string and port that got in the [Step 1](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/redash#step-1-use-terraform-to-provision-ecs-image-and-database-on-alibaba-cloud).

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/redash-create-2.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/redash/images/redash-create-3.png)


Then you can create ``Query``, ``Dashboard`` or work with other BI features on Redash.

You can use Redash to connect to the following database types on Alibaba Cloud:
- [RDS MySQL](https://www.alibabacloud.com/product/apsaradb-for-rds-mysql), refer to Redash features for MySQL: [https://redash.io/data-sources/mysql](https://redash.io/data-sources/mysql)
- [RDS PostgreSQL](https://www.alibabacloud.com/product/apsaradb-for-rds-postgresql), refer to Redash features for PostgreSQL: [https://redash.io/data-sources/postgresql](https://redash.io/data-sources/postgresql)
- [RDS SQL Server](https://www.alibabacloud.com/product/apsaradb-for-rds-sql-server), refer to Redash features for SQL Server: [https://redash.io/data-sources/microsoft-sql-server](https://redash.io/data-sources/microsoft-sql-server)
- [PolarDB MySQL](https://www.alibabacloud.com/product/polardb), refer to Redash features for MySQL: [https://redash.io/data-sources/mysql](https://redash.io/data-sources/mysql)
- [PolarDB PostgreSQL](https://www.alibabacloud.com/product/polardb), refer to Redash features for PostgreSQL: [https://redash.io/data-sources/postgresql](https://redash.io/data-sources/postgresql)
- [PolarDB-O](https://www.alibabacloud.com/product/polardb), refer to Redash features for PostgreSQL: [https://redash.io/data-sources/postgresql](https://redash.io/data-sources/postgresql)
- [MongoDB](https://www.alibabacloud.com/product/apsaradb-for-mongodb), refer to Redash features for MongoDB: [https://redash.io/data-sources/mongodb](https://redash.io/data-sources/mongodb)
- [AnalyticDB MySQL](https://www.alibabacloud.com/product/analyticdb-for-mysql), refer to Redash features for MySQL: [https://redash.io/data-sources/mysql](https://redash.io/data-sources/mysql)
- [AnalyticDB PostgreSQL](https://www.alibabacloud.com/product/hybriddb-postgresql), refer to Redash features for Greenplum: [https://redash.io/data-sources/greenplum](https://redash.io/data-sources/greenplum)
- [ClickHouse](https://www.alibabacloud.com/product/clickhouse), refer to Redash features for ClickHouse: [https://redash.io/data-sources/clickhouse](https://redash.io/data-sources/clickhouse)

For more information about supported data sources in Redash, please refer to [https://redash.io/integrations/](https://redash.io/integrations/).