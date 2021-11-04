# Deploy and Run Azkaban on Alibaba Cloud
Tutorial of running open source project Azkaban on Alibaba Cloud with ApsaraDB (Alibaba Cloud Database). We also show a simple data preparation and migration task deployed and run in Azkaban to demo a data preparation and migration workflow between 2 databases.

You can access the tutorial artifact including deployment script (Terraform), related source code, sample data and instruction guidance from the github project:
[https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/azkaban](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/azkaban)

More tutorial around Alibaba Cloud Database, please refer to:
[https://github.com/alibabacloud-howto/database](https://github.com/alibabacloud-howto/database)

---
### Overview

[Azkaban (https://azkaban.github.io/)](https://azkaban.github.io/) is a batch workflow job scheduler created at LinkedIn to run Hadoop and database jobs. Azkaban resolves the ordering through job dependencies and provides an easy to use web user interface to maintain and track your workflows.

After version 3.0, Azkaban provides two modes: the stand alone “solo-server” mode and distributed multiple-executor mode [reference](https://azkaban.readthedocs.io/en/latest/getStarted.html#getting-started-with-the-solo-server).
- In solo server mode, the DB is embedded H2 and both web server and executor server run in the same process. This should be useful if one just wants to try things out. It can also be used on small scale use cases.
- The multiple executor mode is for most serious production environment. Its DB should be backed by MySQL instances with master-slave set up. The web server and executor servers should ideally run in different hosts so that upgrading and maintenance shouldn’t affect users. This multiple host setup brings in robust and scalable aspect to Azkaban.

To enhance with the database high availability behind the Azkaban, we will show the steps of deployment working with Alibaba Cloud Database RDS MySQL for Azkaban multiple executor mode (in this tutorial, we use only 1 ECS to host both Azkaban web server and one Azkaban executor server).

Azkaban supports the MySQL as the backend database. On Alibaba Cloud, You can either use one of the following databases:
- [RDS MySQL](https://www.alibabacloud.com/product/apsaradb-for-rds-mysql)
- [PolarDB MySQL](https://www.alibabacloud.com/product/polardb)

In this tutorial, we will show the case of using [RDS MySQL](https://www.alibabacloud.com/product/apsaradb-for-rds-mysql) high availability edition for more stable production purpose.

Deployment architecture:

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS and databases on Alibaba Cloud](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/azkaban#step-1-use-terraform-to-provision-ecs-and-database-on-alibaba-cloud)
- [Step 2. Deploy and setup Azkaban on ECS with RDS MySQL](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/azkaban#step-2-deploy-and-setup-azkaban-on-ecs-with-rds-mysql)
- [Step 3. Download and prepare demo Azkaban workflow project package](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/azkaban#step-3-download-and-prepare-demo-azkaban-workflow-project-package)
- [Step 4. Deploy and run the demo Azkaban workflow jobs](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/azkaban#step-4-deploy-and-run-the-demo-azkaban-workflow-jobs)

---
### Step 1. Use Terraform to provision ECS and database on Alibaba Cloud

If you are the 1st time to use Terraform, please refer to [https://github.com/alibabacloud-howto/terraform-templates](https://github.com/alibabacloud-howto/terraform-templates) to learn how to install and use the Terraform on different operating systems.

Run the [terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/azkaban/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use RDS MySQL as backend database of Azkaban and a RDS PostgreSQL as the demo database showing the data preparation and migration via Azkaban task, so ECS, RDS MySQL and RDS PostgreSQL instances are included in the Terraform script). Please specify the necessary information and region to deploy.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/tf-parms.png)

After the Terraform script execution finished, the ECS, RDS MySQL and RDS PostgreSQL instances information are listed as below.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/tf-done.png)

- ``eip_ecs``: The public EIP of the ECS for Azkaban installation host
- ``rds_mysql_url``: The connection URL of the backend RDS MySQL database for Azkaban
- ``rds_pg_url_azkaban_demo_database``: The connection URL of the demo RDS PostgreSQL database using Azkaban
- ``rds_pg_port_azkaban_demo_database``: The connection Port of the demo RDS PostgreSQL database using Azkaban, by default, it is ``5432`` for RDS PostgreSQL (if it was set to ``1921``, please use ``1921`` accordingly)

---
### Step 2. Deploy and setup Azkaban on ECS with RDS MySQL

Please log on to ECS with ``ECS EIP``. By default, the password is ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/ecs-logon.png)

Execute the following commands to install gcc, JDK 8, Git, MySQL client, python3, python module ``psycopg2`` and PostgreSQL client on the ECS.

```bash
yum install -y gcc-c++*
yum install -y java-1.8.0-openjdk-devel.x86_64
yum install -y git
yum install -y mysql.x86_64

yum install -y python39
yum install -y postgresql-devel
pip3 install psycopg2

cd ~
wget http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/compat-openssl10-1.0.2o-3.el8.x86_64.rpm
rpm -i compat-openssl10-1.0.2o-3.el8.x86_64.rpm
wget http://docs-aliyun.cn-hangzhou.oss.aliyun-inc.com/assets/attach/181125/cn_zh/1598426198114/adbpg_client_package.el7.x86_64.tar.gz
tar -xzvf adbpg_client_package.el7.x86_64.tar.gz
```

Execute the following commands to download and build Azkaban project.

```bash
cd ~
git clone https://github.com/azkaban/azkaban.git
cd ~/azkaban
./gradlew clean
./gradlew build installDist -x test
```

Execute the following commands to build module ``azkaban-db``.

```
cd ~/azkaban/azkaban-db; ../gradlew build installDist -x test
```

Then execute the following commands to create all tables needed for Azkaban on RDS MySQL. Please replace ``<rds_mysql_url>`` with the provisioned RDS MySQL connection string.

```
cd ~/azkaban/azkaban-db/build/distributions
unzip azkaban-db-*.zip
```

```
mysql -h<rds_mysql_url> -P3306 -uazkaban -pN1cetest azkaban < ~/azkaban/azkaban-db/build/distributions/azkaban-db-*/create-all-sql-*.sql
```

Then connect to the RDS MySQL again, and execute ``show tables`` to view the created tables for Azkaban.

```
mysql -h<rds_mysql_url> -P3306 -uazkaban -pN1cetest azkaban
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/azkaban_mysql_tables.png)

Execute the following commands to build module ``azkaban-exec-server``, which is the Azkaban Executor Server.

```
cd ~/azkaban/azkaban-exec-server; ../gradlew build installDist -x test
```

Then edit the ``azkaban.properties`` file to modify the properties of executor server accordingly.

```
vim ~/azkaban/azkaban-exec-server/build/install/azkaban-exec-server/conf/azkaban.properties
```

Please refer to [https://docs.oracle.com/javase/8/docs/api/java/time/ZoneId.html](https://docs.oracle.com/javase/8/docs/api/java/time/ZoneId.html) for the property ``default.timezone.id``. Here we locate at China, so set to ``Asia/Shanghai``. Please modify according to your location properly.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/conf_exec_server.png)

Execute the following commands to build module ``azkaban-web-server``, which is the Azkaban Web Server.

```
cd ~/azkaban/azkaban-web-server; ../gradlew build installDist -x test
```

Then edit the ``azkaban.properties`` file to modify the properties of web server accordingly.

```
vim ~/azkaban/azkaban-web-server/build/install/azkaban-web-server/conf/azkaban.properties
```

Please pay attention that ``azkaban.executorselector.filters=StaticRemainingFlowSize,MinimumFreeMemory,CpuStatus`` MUST be replaced with ``azkaban.executorselector.filters=StaticRemainingFlowSize,CpuStatus`` to remove the parameter ``MinimumFreeMemory``.
The web server will check whether the free memory of the executor host will be greater than ``6G``, if it is less than ``6G``, the web server will not hand over the task to the executor host for execution. Since in our tutorial, we use entry level ECS with small memory less than ``6G``, we need to remove this parameter to make the task work.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/conf_web_server.png)

Azkaban web server user account is configured within the following file. Later, we will use the username ``azkaban`` and password ``azkaban`` to log on to the Azkaban web console.

```
vim ~/azkaban/azkaban-web-server/build/install/azkaban-web-server/conf/azkaban-users.xml
```

Now execute the following commands to start the Azkaban executor server.

```
cd ~/azkaban/azkaban-exec-server/build/install/azkaban-exec-server
./bin/start-exec.sh
```

```
curl -G "localhost:$(<./executor.port)/executor?action=activate" && echo
```

Then execute the following commands to start the Azkaban web server.

```
cd ~/azkaban/azkaban-web-server/build/install/azkaban-web-server
./bin/start-web.sh
```

Then, a multi-executor Azkaban instance is ready for use. Open a web browser and check out ``http://<ECS_EIP>:8081/``. We are all set to login to Azkaban web console with username ``azkaban`` and password ``azkaban``.

---
### Step 3. Download and prepare demo Azkaban workflow project package

Azkaban relies on job files in a package to deploy and run the workflow. I've prepared a demo project with scripts, SQL files and job files on this project github.
THIS WILL BE DONE ON YOUR LOCAL COMPUTER. In the local computer, checkout the project to local from github. Please make sure that you have the Git installed on your local computer.

Usually, in [Step 1](https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/azkaban#step-1-use-terraform-to-provision-ecs-and-database-on-alibaba-cloud), if we have already git clone this tutorial project, then we skip this step.

```
git clone https://github.com/alibabacloud-howto/opensource_with_apsaradb.git
```

Then navigate to see the Azkaban demo ETL job files:

```
cd opensource_with_apsaradb/azkaban/project-demo
ls -l
```

We can see the demo Azkaban project files:

- [``_1_prepare_source_db.py``](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/azkaban/project-demo/_1_prepare_source_db.py): Python script to prepare tables and data in source demo database ``northwind_source`` on RDS PostgreSQL
- [``_2_prepare_target_db.py``](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/azkaban/project-demo/_2_prepare_target_db.py): Python script to prepare tables and data in target demo database ``northwind_target`` on RDS PostgreSQL
- [``_3_data_migration.py``](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/azkaban/project-demo/_3_data_migration.py): Python script to migrate data of 2 tables ``products`` and ``orders`` from source database ``northwind_source`` to target database ``northwind_target``
- [``job1_prepare_source_db.job``](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/azkaban/project-demo/job1_prepare_source_db.job): Azkaban job to call ``_1_prepare_source_db.py``
- [``job2_prepare_target_db.job``](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/azkaban/project-demo/job2_prepare_target_db.job): Azkaban job to call ``_2_prepare_target_db.py``
- [``job3_data_migration.job``](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/azkaban/project-demo/job3_data_migration.job): Azkaban job to call ``_3_data_migration.py``, which depends on ``job1_prepare_source_db.job`` and ``job2_prepare_target_db.job`` to execute before hand
- [``northwind_data_source.sql``](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/azkaban/project-demo/northwind_data_source.sql): DML to insert data to source demo database ``northwind_source``
- [``northwind_data_target.sql``](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/azkaban/project-demo/northwind_data_target.sql): DML to insert data to target demo database ``northwind_target``
- [``northwind_ddl.sql``](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/azkaban/project-demo/northwind_ddl.sql): DDL to create tables on both source demo database ``northwind_source`` and target demo database ``northwind_target``

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/job_files.png)

Edit the Azkaban project files accordingly for connecting to the target RDS PostgreSQL demo database. 

```
vim _1_prepare_source_db.py
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/edit_job_py_1.png)

```
vim _2_prepare_target_db.py
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/edit_job_py_2.png)

```
_3_data_migration.py
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/edit_job_py_3.png)

Then execute the following command to package all the project files to a zip package.

```
zip -q -r project_demo_northwind.zip *
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/zip.png)

---
### Step 4. Deploy and run the demo Azkaban workflow jobs

Open a web browser and check out ``http://<ECS_EIP>:8081/``. We are all set to login to Azkaban web console with username ``azkaban`` and password ``azkaban``.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/ui_login.png)

Create a Azkaban project.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/ui_create_project.png)

Upload the project zip file packaged in Step 3.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/ui_upload_zip.png)

Then we can see the job flow.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/ui_job_flow.png)

Click the job entry to see the whole job graph of the workflow.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/ui_job_graph.png)

Then click the ``Schedule / Execute Flow``, and click ``Execute``.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/ui_job_execute.png)

When the workflow execution finished successfully, we can see the green colored job graph.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/ui_job_execute_success.png)

Click ``Job List`` tab, we can see the execution status of 3 jobs of this demo workflow.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/ui_job_list.png)

Now, let's connect to the demo RDS PostgreSQL source and target databases to verify the data.

Execute the following commands to connect to the source database ``northwind_source`` and check the data in tables ``products`` and ``orders``. Please replace ``<rds_pg_url_azkaban_demo_database>`` with the RDS PostgreSQL connection string, the password for RDS PostgreSQL has been preset to ``N1cetest``.

```
cd ~/adbpg_client_package/bin
./psql -h<rds_pg_url_azkaban_demo_database> -p5432 -Udemo northwind_source
```

```
select tablename from pg_tables where schemaname='public';
select count(*) from products;
select count(*) from orders;
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/job_done_db_verify_1.png)

Execute the following commands to connect to the target database ``northwind_target`` and check the data in tables ``products`` and ``orders``. Please replace ``<rds_pg_url_azkaban_demo_database>`` with the RDS PostgreSQL connection string, the password for RDS PostgreSQL has been preset to ``N1cetest``.

```
cd ~/adbpg_client_package/bin
./psql -h<rds_pg_url_azkaban_demo_database> -p5432 -Udemo northwind_target
```

```
select tablename from pg_tables where schemaname='public';
select count(*) from products;
select count(*) from orders;
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/azkaban/images/job_done_db_verify_2.png)

