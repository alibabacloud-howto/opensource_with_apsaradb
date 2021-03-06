# Deploy and Run Superset on Alibaba Cloud with Alibaba Cloud Database
Running open source project Apache Superset on Alibaba Cloud with ApsaraDB (Alibaba Cloud Database).

You can access the tutorial artifact including deployment script (Terraform), related source code, sample data and instruction guidance from the github project:
[https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-superset](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-superset)

More tutorial around Alibaba Cloud Database, please refer to:
[https://github.com/alibabacloud-howto/database](https://github.com/alibabacloud-howto/database)

---
### Overview
[Superset (https://superset.apache.org/)](https://superset.apache.org/) is a modern data exploration and visualization platform.
To enhance with the database high availability behind the Superset data exploration and visualization, we will show the steps of deployment working with Alibaba Cloud Database Family.

In this tutorial, we will use the [Superset image](https://marketplace.alibabacloud.com/products/56698003/Apache_em_Superset_em_on_Ubuntu-sgcmjj00025684.html) in Alibaba Cloud Marketplace, which is well packaged and configured for easy starting and future version upgrading.
For more administration guide of this Superset image, please refer to: https://support.websoft9.com/docs/superset

Deployment architecture:

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS image and database on Alibaba Cloud](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-superset#step-1-use-terraform-to-provision-ecs-image-and-database-on-alibaba-cloud)
- [Step 2. Setup connection to RDS PostgreSQL](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-superset#step-2-setup-connection-to-rds-postgresql)

---
### Step 1. Use Terraform to provision ECS image and database on Alibaba Cloud

If you are the 1st time to use Terraform, please refer to [https://github.com/alibabacloud-howto/terraform-templates](https://github.com/alibabacloud-howto/terraform-templates) to learn how to install and use the Terraform on different operating systems.

Run the [terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-superset/deployment/terraform/main.tf) to initialize the resources. 
Within the terraform script, please use the right ``Image ID`` of [Superset image on the corresponding region](https://marketplace.alibabacloud.com/products/56698003/Apache_em_Superset_em_on_Ubuntu-sgcmjj00025684.html).

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/superset_image.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/superset_image_in_tf.png)

After the Terraform script execution, open the following URL in a Web browser to initialize Superset: 

```bash
http://<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/tf_done.png)

Please log on to ECS and visit the Superset credential file to get the initial administrator username and password. By default, the password is ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>

vim /credentials/password.txt
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/ecs_logon.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/superset_passwword.png)

Then back to Superset log on page, and input the administrator user name and password to log on, you will see the main page.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/superset_logon.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/superset_main.png)

---
### Step 2. Setup connection to RDS PostgreSQL

On the Superset web page, go to ``Data`` -> ``Databases`` to add RDS PostgreSQL as a database.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-superset/images/rds_pg_config.png)

In the ``SQLALCHEMY URI``, input the RDS PostgreSQL URI following this pattern: ``postgresql://<username>:<password>@<rds_postgresql_domain>:<rds_postgresql_port>/<schema>``, such as ``postgresql://superset:superset@pgm-gs5n44yc841r4y5y70490.pgsql.singapore.rds.aliyuncs.com:1921/superset``.

Then you can setup ``Dataset``, ``Chart``, ``Dashboard`` or work with other BI features on Superset.

You can use Superset to connect to the following database types on Alibaba Cloud:
- [RDS MySQL](https://www.alibabacloud.com/product/apsaradb-for-rds-mysql), connection URI reference: [https://superset.apache.org/docs/databases/mysql](https://superset.apache.org/docs/databases/mysql)
- [RDS PostgreSQL](https://www.alibabacloud.com/product/apsaradb-for-rds-postgresql), connection URI reference: [https://superset.apache.org/docs/databases/postgres](https://superset.apache.org/docs/databases/postgres)
- [RDS SQL Server](https://www.alibabacloud.com/product/apsaradb-for-rds-sql-server), connection URI reference: [https://superset.apache.org/docs/databases/sql-server](https://superset.apache.org/docs/databases/sql-server)
- [PolarDB MySQL](https://www.alibabacloud.com/product/polardb), connection URI reference: [https://superset.apache.org/docs/databases/mysql](https://superset.apache.org/docs/databases/mysql)
- [PolarDB PostgreSQL](https://www.alibabacloud.com/product/polardb), connection URI reference: [https://superset.apache.org/docs/databases/postgres](https://superset.apache.org/docs/databases/postgres)
- [PolarDB-O](https://www.alibabacloud.com/product/polardb), connection URI reference: [https://superset.apache.org/docs/databases/postgres](https://superset.apache.org/docs/databases/postgres)
- [AnalyticDB MySQL](https://www.alibabacloud.com/product/analyticdb-for-mysql), connection URI reference: [https://superset.apache.org/docs/databases/mysql](https://superset.apache.org/docs/databases/mysql)
- [AnalyticDB PostgreSQL](https://www.alibabacloud.com/product/hybriddb-postgresql), connection URI reference: [https://superset.apache.org/docs/databases/postgres](https://superset.apache.org/docs/databases/postgres)
- [ClickHouse](https://www.alibabacloud.com/product/clickhouse), connection URI reference: [https://superset.apache.org/docs/databases/clickhouse](https://superset.apache.org/docs/databases/clickhouse)

For more information about database URI in Superset, please refer to [https://superset.apache.org/docs/databases/installing-database-drivers](https://superset.apache.org/docs/databases/installing-database-drivers).