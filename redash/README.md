# Deploy and Run Redash on Alibaba Cloud
Running open source project Redash on Alibaba Cloud with ApsaraDB (Alibaba Cloud Database).

---
### Overview
[Redash (https://redash.io/)](https://redash.io/) is designed to enable anyone, regardless of the level of technical sophistication, to harness the power of data big and small. SQL users leverage Redash to explore, query, visualize, and share data from any data sources. Their work in turn enables anybody in their organization to use the data. Every day, millions of users at thousands of organizations around the world use Redash to develop insights and make data-driven decisions.
To enhance with the database high availability behind the Redash data exploration and visualization, we will show the steps of deployment working with Alibaba Cloud Database Family.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/worldbank_dashboard.png)

In this tutorial, we will use the official [Setup](https://github.com/getredash/setup) script to deploy Redash with Docker on Ubuntu on Alibaba Cloud ECS.

Deployment architecture:

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS image and database on Alibaba Cloud](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-superset#step-1-use-terraform-to-provision-ecs-image-and-database-on-alibaba-cloud)
- [Step 2. Deploy and setup Redash on ECS](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-superset#step-1-use-terraform-to-provision-ecs-image-and-database-on-alibaba-cloud)
- [Step 3. Setup connection to RDS PostgreSQL](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-superset#step-2-setup-connection-to-rds-postgresql)

---
### Step 1. Use Terraform to provision ECS image and database on Alibaba Cloud

Run the [terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-superset/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use RDS PostgreSQL as example data source for Redash, so ECS and RDS PostgreSQL instances are included in the Terraform script). Please specify the necessary information and region to deploy.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/tf_done.png)

After the Terraform script execution finished, the ECS and RDS PostgreSQL instance information are listed as below.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/tf_done.png)

### Step 2. Deploy and setup Redash on ECS

Please log on to ECS with ``ECS EIP``.

```bash
ssh root@<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/ecs_logon.png)

Then execute the following commands to setup the Redash.

```bash
mkdir /opt/redash
wget https://raw.githubusercontent.com/getredash/setup/master/setup.sh
sh setup.sh
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/ecs_logon.png)

After the setup script execution finished, open the following URL in a Web browser to initialize Redash: 

```bash
http://<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/superset_logon.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/superset_main.png)

---
### Step 3. Setup connection to RDS PostgreSQL

On the Redash web page, go to ``Data`` -> ``Databases`` to add RDS PostgreSQL as a database.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/rds_pg_config.png)

In the ``SQLALCHEMY URI``, input the RDS PostgreSQL URI following this pattern: ``postgresql://<username>:<password>@<rds_postgresql_domain>:<rds_postgresql_port>/<schema>``, such as ``postgresql://superset:superset@pgm-gs5n44yc841r4y5y70490.pgsql.singapore.rds.aliyuncs.com:1921/superset``.

Then you can setup ``Dataset``, ``Chart``, ``Dashboard`` or work with other BI features on Superset.
![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/covid-19_dashboard.png)

You can use Redash to connect to the following database types on Alibaba Cloud:
- [RDS MySQL](https://www.alibabacloud.com/product/apsaradb-for-rds-mysql), Redash features for MySQL: [https://redash.io/data-sources/mysql](https://redash.io/data-sources/mysql)
- [RDS PostgreSQL](https://www.alibabacloud.com/product/apsaradb-for-rds-postgresql), Redash features for MySQL: [https://redash.io/data-sources/mysql](https://redash.io/data-sources/mysql)
- [RDS SQL Server](https://www.alibabacloud.com/product/apsaradb-for-rds-sql-server), Redash features for MySQL: [https://redash.io/data-sources/mysql](https://redash.io/data-sources/mysql)
- [PolarDB MySQL](https://www.alibabacloud.com/product/polardb), Redash features for MySQL: [https://redash.io/data-sources/mysql](https://redash.io/data-sources/mysql)
- [PolarDB PostgreSQL](https://www.alibabacloud.com/product/polardb), Redash features for MySQL: [https://redash.io/data-sources/mysql](https://redash.io/data-sources/mysql)
- [PolarDB-O](https://www.alibabacloud.com/product/polardb), Redash features for MySQL: [https://redash.io/data-sources/mysql](https://redash.io/data-sources/mysql)
- [AnalyticDB MySQL](https://www.alibabacloud.com/product/analyticdb-for-mysql), Redash features for MySQL: [https://redash.io/data-sources/mysql](https://redash.io/data-sources/mysql)
- [AnalyticDB PostgreSQL](https://www.alibabacloud.com/product/hybriddb-postgresql), Redash features for MySQL: [https://redash.io/data-sources/mysql](https://redash.io/data-sources/mysql)
- [ClickHouse](https://www.alibabacloud.com/product/clickhouse), Redash features for MySQL: [https://redash.io/data-sources/mysql](https://redash.io/data-sources/mysql)

For more information about supported data sources in Redash, please refer to [https://redash.io/integrations/](https://redash.io/integrations/).