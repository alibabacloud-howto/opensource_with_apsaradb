# Build and Run ETL Data Pipeline and BI with Luigi and Metabase on Alibaba Cloud

You can access the tutorial artifact including deployment script (Terraform), related source code, sample data and instruction guidance from the github project:
[https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/luigi_metabase](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/luigi_metabase)

More tutorial around Alibaba Cloud Database, please refer to:
[https://github.com/alibabacloud-howto/database](https://github.com/alibabacloud-howto/database)

---
### Overview

[Luigi (https://github.com/spotify/luigi)](https://github.com/spotify/luigi) is a Python (3.6, 3.7, 3.8, 3.9 tested) package that helps you build complex pipelines of batch jobs. It handles dependency resolution, workflow management, visualization, handling failures, command line integration, and much more. Document reference: [https://luigi.readthedocs.io/en/stable/](https://luigi.readthedocs.io/en/stable/).

[Metabase (https://www.metabase.com/)](https://www.metabase.com/) is an open source business intelligence tool. It lets user ask questions about the data, and displays answers in formats that make sense, whether that’s a bar graph or a detailed table. Metabase uses the default application database (H2) when initially start using Metabase. To enhance with the database high availability behind the Metabase BI Server, we will use Alibaba Cloud Database RDS PostgreSQL as the backend database of Metabase.
Metabase supports either PostgreSQL or MySQL as the backend database. On Alibaba Cloud, You can either use one of the following databases:
- [RDS MySQL](https://www.alibabacloud.com/product/apsaradb-for-rds-mysql)
- [RDS PostgreSQL](https://www.alibabacloud.com/product/apsaradb-for-rds-postgresql)
- [PolarDB MySQL/PostgreSQL](https://www.alibabacloud.com/product/polardb)

In this tutorial, we will show the case of using [RDS PostgreSQL](https://www.alibabacloud.com/product/apsaradb-for-rds-postgresql) high availability edition for more stable production purpose.

Deployment architecture:

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS and databases on Alibaba Cloud](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/luigi_metabase#step-1-use-terraform-to-provision-ecs-and-database-on-alibaba-cloud)
- [Step 2. Deploy and setup Luigi and Metabase on ECS with RDS PostgreSQL](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/luigi_metabase#step-2-deploy-and-setup-luigi-and-metabase-on-ecs-with-rds-postgresql)
- [Step 3. Setup the demo RDS PostgreSQL database](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/luigi_metabase#step-3-setup-the-demo-rds-postgresql-database)
- [Step 4. Run the demo ETL data pipeline on Luigi](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/luigi_metabase#step-4-run-the-demo-etl-data-pipeline-on-luigi)
- [Step 5. View the data in demo RDS PostgreSQL and BI report on Metabase](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/luigi_metabase#step-5-view-the-data-in-demo-rds-postgresql-and-bi-report-on-metabase)

---
### Step 1. Use Terraform to provision ECS and database on Alibaba Cloud

Run the [terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/luigi_metabase/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use RDS PostgreSQL as backend database of Metabase and a RDS PostgreSQL as the demo database showing the ETL data pipeline via Luigi task and BI in Metabase, so ECS and 2 RDS PostgreSQL instances are included in the Terraform script). Please specify the necessary information and region to deploy.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/tf-parms.png)

After the Terraform script execution finished, the ECS and RDS PostgreSQL instances information are listed as below.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/tf-done.png)

- ``eip_ecs``: The public EIP of the ECS for Azkaban installation host
- ``rds_pg_url_metabase_database``: The connection URL of the backend RDS PostgreSQL database for Metabase
- ``rds_pg_port_metabase_database``: The connection port of the backend RDS PostgreSQL database for Metabase, by default, it is ``1921`` for RDS PostgreSQL 
- ``rds_pg_url_demo_database``: The connection URL of the demo RDS PostgreSQL database using Luigi and Metabase
- ``rds_pg_port_demo_database``: The connection Port of the demo RDS PostgreSQL database using Luigi and Metabase, by default, it is ``1921`` for RDS PostgreSQL 

---
### Step 2. Deploy and setup Luigi and Metabase on ECS with RDS PostgreSQL

Please log on to ECS with ``ECS EIP``.

```bash
ssh root@<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/ecs-logon.png)


Execute the following command to install gcc, python, related python modules, Luigi, JDK 8, Git and PostgreSQL client.

```bash
yum install -y gcc-c++*
yum install -y python39
yum install -y postgresql-devel
pip3 install psycopg2
pip3 install pandas
pip3 install mlxtend
pip3 install pycountry
pip3 install luigi

yum install -y java-1.8.0-openjdk-devel.x86_64
yum install -y git

cd ~
wget http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/compat-openssl10-1.0.2o-3.el8.x86_64.rpm
rpm -i compat-openssl10-1.0.2o-3.el8.x86_64.rpm
wget http://docs-aliyun.cn-hangzhou.oss.aliyun-inc.com/assets/attach/181125/cn_zh/1598426198114/adbpg_client_package.el7.x86_64.tar.gz
tar -xzvf adbpg_client_package.el7.x86_64.tar.gz
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/git-install-done.png)

Execute the commands to checkout the project files from Github and navigate to the project directory.

```
git clone https://github.com/alibabacloud-howto/opensource_with_apsaradb.git
cd opensource_with_apsaradb/luigi_metabase/
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/git-checkout-done.png)

In this tutorial, I show the Metabase execution approach via [running the Metabase JAR file](https://www.metabase.com/docs/latest/operations-guide/running-the-metabase-jar-file.html).
So please execute the following commands to download the Metabase JAR file.

```
cd ~/opensource_with_apsaradb/luigi_metabase/metabase
wget https://downloads.metabase.com/v0.40.3.1/metabase.jar
```

By default, Metabase uses the default application database (H2) when initially start using Metabase. But in this tutorial, I show the best practice of switching to a more production-ready database RDS PostgreSQL.
Basically, it follows the official document [Migrating from using the H2 database to Postgres or MySQL/MariaDB](https://www.metabase.com/docs/latest/operations-guide/migrating-from-h2.html).
Execute the following commands to migration Metabase backend database from H2 to RDS PostgreSQL that was provisioned before in the Step 1.
Please update ``<rds_pg_url_metabase_database>`` with the corresponding connection string.

```
cd ~/opensource_with_apsaradb/luigi_metabase/metabase
export MB_DB_TYPE=postgres
export MB_DB_DBNAME=metabase
export MB_DB_PORT=1921
export MB_DB_USER=metabase
export MB_DB_PASS=N1cetest
export MB_DB_HOST=<rds_pg_url_metabase_database>
java -jar metabase.jar load-from-h2 ~/opensource_with_apsaradb/luigi_metabase/metabase/metabase.db
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/metabase_h2_pg_migration_command.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/metabase_h2_pg_migration.png)

Then execute the command to start Metabase using the RDS PostgreSQL as the backend database. Please update ``<rds_pg_url_metabase_database>`` with the corresponding connection string.

```
export MB_DB_TYPE=postgres
export MB_DB_DBNAME=metabase
export MB_DB_PORT=1921
export MB_DB_USER=metabase
export MB_DB_PASS=N1cetest
export MB_DB_HOST=<rds_pg_url_metabase_database>
java -jar metabase.jar
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/metabase_start_command.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/metabase_start_done.png)

Once it is up and running, navigate to ``http://<ECS_EIP>:3000/``

I've preset the following accounts in demo Metabase, please logon with the ``Admin User``.
- ``Admin User``: ``admin@somebusiness.com``
- ``Password``: ``N1cetest``
- ``Business Owner user``: ``owner@somebusiness.com``
- ``Password``: ``N1cetest``

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/metabase_logon.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/metabase_logon_done.png)

---
### Step 3. Setup the demo RDS PostgreSQL database

Please log on to ECS with ``ECS EIP`` in another CLI window (DO NOT close the CLI window logged in Step 2).

```bash
ssh root@<ECS_EIP>
```

Before we demo the ETL data pipeline, let's execute the following commands to create the schema ``sales_dw`` and tables (CREATE TABLE DDL are within the SQL file [https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/luigi_metabase/sales_dw_ddl.sql](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/luigi_metabase/sales_dw_ddl.sql)) in the demo RDS PostgreSQL database.
Please replace ``<rds_pg_url_demo_database>`` with the corresponding connection string of the demo RDS PostgreSQL instance. When prompting the password of connecting to the schema ``sales_dw``, please input ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```
cd ~/adbpg_client_package/bin
./psql -h<rds_pg_url_demo_database> -p1921 -Udemo sales_dw
```

In the PG client, execute the DDL SQL file and check that 6 empty tables are created.

```
\i ~/opensource_with_apsaradb/luigi_metabase/sales_dw_ddl.sql
select tablename from pg_tables where schemaname='public';
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/metabase_demo_db.png)

There are 3 tables as the source tables and 3 tables as the target tables in the demo ETL data pipeline:
- ``product_info``: a source table in the demo ETL data pipeline
- ``invoice``: a source table in the demo ETL data pipeline
- ``customer_info``: a source table in the demo ETL data pipeline
- ``invoice_time``: a target table in the demo ETL data pipeline
- ``invoice_outliers`` a target table in the demo ETL data pipeline
- ``association_rules`` a target table in the demo ETL data pipeline

---
### Step 4. Run the demo ETL data pipeline on Luigi

Please log on to ECS with ``ECS EIP`` in another new CLI window (DO NOT close the CLI window logged in Step 2 and Step 3).

```bash
ssh root@<ECS_EIP>
```

Within this CLI window, execute the command to start luigi daemon.

```
luigid
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/luigid.png)

Once it is up and running, navigate to ``http://<ECS_EIP>:8082/``

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/luigi_main.png)

Now, we can run the ETL data pipeline in Luigi. The following image shows the ETL data pipeline workflow in the demo.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/data_pipeline.png)

Basically, the full ETL data pipeline code are in [https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/luigi_metabase/data_pipeline.py](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/luigi_metabase/data_pipeline.py).
It will load the raw data in the local ECS disk under [https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/luigi_metabase/data](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/luigi_metabase/data), then process and transform the data to local disk, and finally load the data into the RDS PostgreSQL database for Metabase BI reporting. The BI reports in Metabase has already been composed in this demo within Metabase.

Switch to the CLI window created at Step 3. Before execution, please edit the pipeline python code to change the demo database connection string URL to the value of ``<rds_pg_url_demo_database>``.

```
cd ~/opensource_with_apsaradb/luigi_metabase
vim data_pipeline.py
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/pipeline_code.png)

Then execute the following commands to kick off a pipeline execution for the data at ``2018-03-30`` in this CLI window.

```
cd ~/opensource_with_apsaradb/luigi_metabase
PYTHONPATH='.' luigi --module data_pipeline CompleteDataDumpLoad --date 2018-03-30
```

The data pipeline execution summary shows at the end.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/pipeline_execution.png)

Refresh the Luigi web page ``http://<ECS_EIP>:8082/``, you can see the data pipeline execution information.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/luigi_web_1.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/luigi_web_2.png)

---
### Step 5. View the data in demo RDS PostgreSQL and BI report on Metabase

In the CLI window created at Step 3, execute the following commands to verify the data processed in the data pipeline.
Please replace ``<rds_pg_url_demo_database>`` with the corresponding connection string of the demo RDS PostgreSQL instance. When prompting the password of connecting to the schema ``sales_dw``, please input ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```
cd ~/adbpg_client_package/bin
./psql -h<rds_pg_url_demo_database> -p1921 -Udemo sales_dw
```

In the PG client, execute the SQL to view the data.

```
select tablename from pg_tables where schemaname='public';
select count(*) from association_rules; 
select count(*) from product_info;
select count(*) from invoice;
select count(*) from customer_info;
select count(*) from invoice_time;
select count(*) from invoice_outliers;
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/data_verify.png)

Then navigate to Metabase database ``Admin`` setting to update the target database to the demo RDS PostgreSQL database ``<rds_pg_url_demo_database>``.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/metabase_admin.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/metabase_database.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/metabase_exit_admin.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/metabase_dashboard_1.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/metabase_dashboard_2.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/metabase_dashboard_3.png)


This tutorial is modified based on [https://github.com/abhishekzambre/data-warehouse](https://github.com/abhishekzambre/data-warehouse) to run on Alibaba Cloud. There are some errors in the original source code, I've already fixed them and made them all work on Alibaba Cloud.