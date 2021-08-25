# Deploy and Run Apache Airflow on Alibaba Cloud
Running open source project Apache Airflow on Alibaba Cloud with ApsaraDB (Alibaba Cloud Database). We also show a simple data migration task deployed and run in Airflow to migrate data between 2 databases.

---
### Overview

[Apache Airflow (https://airflow.apache.org/)](https://airflow.apache.org/) is a platform created by the community to programmatically author, schedule and monitor workflows.

Airflow requires a database. If you're just experimenting and learning Airflow, you can stick with the default SQLite option or single node PostgreSQL built in Docker edition. To enhance with the database high availability behind the Apache Airflow, we will show the steps of deployment working with Alibaba Cloud Database.
Airflow supports PostgreSQL and MySQL [https://airflow.apache.org/docs/apache-airflow/stable/howto/set-up-database.html](https://airflow.apache.org/docs/apache-airflow/stable/howto/set-up-database.html). You can either use one of the following databases on Alibaba Cloud:
- [RDS MySQL](https://www.alibabacloud.com/product/apsaradb-for-rds-mysql)
- [RDS PostgreSQL](https://www.alibabacloud.com/product/apsaradb-for-rds-postgresql)
- [PolarDB MySQL](https://www.alibabacloud.com/product/polardb)
- [PolarDB PostgreSQL](https://www.alibabacloud.com/product/polardb)

In this tutorial, we will show the case of using [RDS PostgreSQL](https://www.alibabacloud.com/product/apsaradb-for-rds-postgresql) high availability edition to replace the single node PostgreSQL built in Docker edition for more stable production purpose.

Deployment architecture:

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS and databases on Alibaba Cloud]()
- [Step 2. Deploy and setup Airflow on ECS with RDS PostgreSQL]()

---
### Step 1. Use Terraform to provision ECS and database on Alibaba Cloud

Run the [terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-airflow/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use RDS PostgreSQL as backend database of Airflow and another RDS PostgreSQL as the demo database showing the data migration via Airflow task, so ECS and 2 RDS PostgreSQL instances are included in the Terraform script). Please specify the necessary information and region to deploy.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/tf-parms.png)

After the Terraform script execution finished, the ECS and RDS PostgreSQL instances information are listed as below.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/tf-done.png)

### Step 2. Deploy and setup Airflow on ECS with RDS PostgreSQL

Please log on to ECS with ``ECS EIP``.

```bash
ssh root@<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/ecs-logon.png)

Download and execute the script [``setup.sh``](https://raw.githubusercontent.com/alibabacloud-howto/opensource_with_apsaradb/main/apache-airflow/setup.sh) via the following commands to setup Airflow on ECS.

```bash
cd ~
wget https://raw.githubusercontent.com/alibabacloud-howto/opensource_with_apsaradb/main/apache-airflow/setup.sh
sh setup.sh
mkdir ./dags ./logs ./plugins
echo -e "AIRFLOW_UID=$(id -u)\nAIRFLOW_GID=0" > .env
```

```
docker-compose up airflow-init
docker-compose up
```

http://<ECS_EIP>:8080

The default account has the login ``airflow`` and the password ``airflow``.




### Setup psql for demo

Download and setup AnalyticDB for PostgreSQL client.

```bash
wget http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/compat-openssl10-1.0.2o-3.el8.x86_64.rpm
rpm -i compat-openssl10-1.0.2o-3.el8.x86_64.rpm
wget http://docs-aliyun.cn-hangzhou.oss.aliyun-inc.com/assets/attach/181125/cn_zh/1598426198114/adbpg_client_package.el7.x86_64.tar.gz
tar -xzvf adbpg_client_package.el7.x86_64.tar.gz
cd adbpg_client_package/bin
```

### Download the sample Northwind database and data

There are DDL and INSERT scripts we’ll need to download so we can build our demo.

Connect to the demo RDS PostgreSQL database ``northwind_source``, create the tables (``northwind_ddl.sql``) and load the sample data (``northwind_data_source.sql``).

```
./psql -hpgm-gs5jm643941l6mw4154270.pgsql.singapore.rds.aliyuncs.com -p1921 -Udemo northwind_source

\i ~/airflow/northwind_ddl.sql
\i ~/airflow/northwind_data.sql

select tablename from pg_tables where schemaname='public';
select count(*) from products;
select count(*) from orders;

./psql -hpgm-gs5jm643941l6mw4154270.pgsql.singapore.rds.aliyuncs.com -p1921 -Udemo northwind_target

\i ~/airflow/northwind_ddl.sql
\i ~/airflow/northwind_data.sql

select tablename from pg_tables where schemaname='public';
select count(*) from products;
select count(*) from orders;
```

The DAG in this demo finds the new ``product_id`` and ``order_id``’s in database ``northwind_source`` and then updates the same product and order tables in database ``northwind_target`` with the rows greater than that maximum id. The job is scheduled to run every minute starting on today’s date (when you run this demo, please update accordingly).
The demo airflow DAG python script is originated from [https://dzone.com/articles/part-2-airflow-dags-for-migrating-postgresql-data](https://dzone.com/articles/part-2-airflow-dags-for-migrating-postgresql-data), I've done some modification.

cd ~/airflow/dags
wget .../