# Deploy and Run Apache Airflow on Alibaba Cloud
Tutorial of running open source project Apache Airflow on Alibaba Cloud with ApsaraDB (Alibaba Cloud Database). We also show a simple data migration task deployed and run in Airflow to migrate data between 2 databases.

You can access the tutorial artifact including deployment script (Terraform), related source code, sample data and instruction guidance from the github project:
[https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-airflow](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-airflow)

More tutorial around Alibaba Cloud Database, please refer to:
[https://github.com/alibabacloud-howto/database](https://github.com/alibabacloud-howto/database)

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

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS and databases on Alibaba Cloud](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-airflow#step-1-use-terraform-to-provision-ecs-and-database-on-alibaba-cloud)
- [Step 2. Deploy and setup Airflow on ECS with RDS PostgreSQL](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-airflow#step-2-deploy-and-setup-airflow-on-ecs-with-rds-postgresql)
- [Step 3. Prepare the source and target database for Airflow data migration task demo](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-airflow#step-3-prepare-the-source-and-target-database-for-airflow-data-migration-task-demo)
- [Step 4. Deploy and run data migration task in Airflow](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/apache-airflow#step-4-deploy-and-run-data-migration-task-in-airflow)

---
### Step 1. Use Terraform to provision ECS and database on Alibaba Cloud

Run the [terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-airflow/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use RDS PostgreSQL as backend database of Airflow and another RDS PostgreSQL as the demo database showing the data migration via Airflow task, so ECS and 2 RDS PostgreSQL instances are included in the Terraform script). Please specify the necessary information and region to deploy.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/tf-parms.png)

After the Terraform script execution finished, the ECS and RDS PostgreSQL instances information are listed as below.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/tf-done.png)

- ``rds_pg_url_airflow_database``: The connection URL of the backend database for Airflow
- ``rds_pg_url_airflow_demo_database``: The connection URL of the demo database using Airflow

The database port for RDS PostgreSQL is ``1921`` by default.

### Step 2. Deploy and setup Airflow on ECS with RDS PostgreSQL

Please log on to ECS with ``ECS EIP``. By default, the password is ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/ecs-logon.png)

Download and execute the script [``setup.sh``](https://raw.githubusercontent.com/alibabacloud-howto/opensource_with_apsaradb/main/apache-airflow/setup.sh) via the following commands to setup Airflow on ECS.

```bash
cd ~
wget https://raw.githubusercontent.com/alibabacloud-howto/opensource_with_apsaradb/main/apache-airflow/setup.sh
sh setup.sh
cd ~/airflow
mkdir ./dags ./logs ./plugins
echo -e "AIRFLOW_UID=$(id -u)\nAIRFLOW_GID=0" > .env
```

Edit the downloaded ``docker-compose.yaml`` file to set the backend database as the RDS PostgreSQL.

```
cd ~/airflow
vim docker-compose.yaml
```

Use the connection string of ``rds_pg_url_airflow_database`` in Step 1. Comment the part related the ``postgres``.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/docker-compose-1.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/docker-compose-2.png)

Then execute the following command to initialize Airflow docker.

```
docker-compose up airflow-init
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/airflow-inited.png)

Then execute the following command to start Airflow.

```
docker-compose up
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/airflow-started.png)

Now, Airflow has started successfully. Please visit the following URL (replace ``<ECS_EIP>`` with the EIP of the ECS) to access the Airflow web console.

```
http://<ECS_EIP>:8080
```

The default account has the login ``airflow`` and the password ``airflow``.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/airflow-login.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/airflow-logined.png)

Next, let's move on to work on the 1st data migration task on Airflow.

### Step 3. Prepare the source and target database for Airflow data migration task demo

Please log on to ECS with ``ECS EIP`` within another terminal window.

```bash
ssh root@<ECS_EIP>
```

Download and setup PostgreSQL client to communicate with the demo database.

```bash
cd ~
wget http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/compat-openssl10-1.0.2o-3.el8.x86_64.rpm
rpm -i compat-openssl10-1.0.2o-3.el8.x86_64.rpm
wget http://docs-aliyun.cn-hangzhou.oss.aliyun-inc.com/assets/attach/181125/cn_zh/1598426198114/adbpg_client_package.el7.x86_64.tar.gz
tar -xzvf adbpg_client_package.el7.x86_64.tar.gz
```

Fetch the database DDL and DML SQL files.
- [northwind_ddl.sql](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-airflow/northwind_ddl.sql) for both source and target database
- [northwind_data_source.sql](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-airflow/northwind_data_source.sql) for the source database
- [northwind_data_target.sql](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-airflow/northwind_data_target.sql) for the target database

```
cd ~/airflow
wget https://raw.githubusercontent.com/alibabacloud-howto/opensource_with_apsaradb/main/apache-airflow/northwind_ddl.sql
wget https://raw.githubusercontent.com/alibabacloud-howto/opensource_with_apsaradb/main/apache-airflow/northwind_data_source.sql
wget https://raw.githubusercontent.com/alibabacloud-howto/opensource_with_apsaradb/main/apache-airflow/northwind_data_target.sql
```

There are 2 databases (source: ``northwind_source``, target: ``northwind_target``) working as the source and target respectively in this data migration demo.

Connect to the demo source database ``northwind_source``, create the tables (``northwind_ddl.sql``) and load the sample data (``northwind_data_source.sql``).
Replace ``<rds_pg_url_airflow_demo_database>`` with the demo RDS PostgreSQL connection string.
We've set up the demo database account as username ``demo`` and password ``N1cetest``.

Execute the following commands for the source database:

```
cd ~/adbpg_client_package/bin
./psql -h<rds_pg_url_airflow_demo_database> -p1921 -Udemo northwind_source

\i ~/airflow/northwind_ddl.sql
\i ~/airflow/northwind_data_source.sql

select tablename from pg_tables where schemaname='public';
select count(*) from products;
select count(*) from orders;
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/source_data.png)

Execute the following commands for the target database:

```
./psql -h<rds_pg_url_airflow_demo_database> -p1921 -Udemo northwind_target

\i ~/airflow/northwind_ddl.sql
\i ~/airflow/northwind_data_target.sql

select tablename from pg_tables where schemaname='public';
select count(*) from products;
select count(*) from orders;
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/target_data.png)

We can see that tables ``products`` and ``orders`` in the target database are empty. Later we will use the migration task running in Airflow to migrate data from the source database to the target database.

### Step 4. Deploy and run data migration task in Airflow

First, go to the Airflow web console (``Admin`` -> ``Connections``) to add database connections to the source and target databases respectively.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/airflow_conn.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/source_conn.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/target_conn.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/conn_list.png)

Download and deploy (put into the ``dags`` directory) the migration task python script [https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-airflow/northwind_migration.py](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-airflow/northwind_migration.py) into Airflow.

```
cd ~/airflow/dags
wget https://raw.githubusercontent.com/alibabacloud-howto/opensource_with_apsaradb/main/apache-airflow/northwind_migration.py
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/dag.png)

The DAG task in this demo finds the new ``product_id`` and ``order_id``’s in database ``northwind_source`` and then updates the same product and order tables in database ``northwind_target`` with the rows greater than that maximum id. The job is scheduled to run every minute starting on today’s date (when you run this demo, please update accordingly).
The demo airflow DAG python script is originated from [https://dzone.com/articles/part-2-airflow-dags-for-migrating-postgresql-data](https://dzone.com/articles/part-2-airflow-dags-for-migrating-postgresql-data), We've done some modification.

If the task loaded successfully, the DAG task is shown on the web console.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/dag_task_1.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/dag_task_2.png)

Since the migration task is running all the times, we can go to the target database and check the data migrated.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/verify_target.png)