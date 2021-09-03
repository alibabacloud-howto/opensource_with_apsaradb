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

```
git clone https://github.com/alibabacloud-howto/opensource_with_apsaradb.git
cd opensource_with_apsaradb/luigi_metabase/
```

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

Once it is up and running, navigate to ``http://<ECS_EIP>:3000/``

Admin User: admin@somebusiness.com
Password: N1cetest
Business Owner user: owner@somebusiness.com
Password: N1cetest

```
cd ~/adbpg_client_package/bin
./psql -hpgm-3nsp9729e9aql1t9168190.pg.rds.aliyuncs.com -p1921 -Udemo sales_dw

\i ~/opensource_with_apsaradb/luigi_metabase/sales_dw_ddl.sql
select tablename from pg_tables where schemaname='public';
```


Execute the command to start luigi daemon.

```
luigid
```

Once it is up and running, navigate to ``http://<ECS_EIP>:8082/``

```
cd ~/opensource_with_apsaradb/luigi_metabase
PYTHONPATH='.' luigi --module data_pipeline CompleteDataDumpLoad --date 2018-03-30
```


```
cd ~/adbpg_client_package/bin
./psql -hpgm-3nsa364dun8rza5k168190.pg.rds.aliyuncs.com -p1921 -Udemo sales_dw
select tablename from pg_tables where schemaname='public';
```



This tutorial is modified based on [https://github.com/abhishekzambre/data-warehouse](https://github.com/abhishekzambre/data-warehouse) to running on Alibaba Cloud. There are some errors in the original source code, I've already fixed them and made them all work on Alibaba Cloud.