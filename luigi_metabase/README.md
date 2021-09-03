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

- [Step 1. Use Terraform to provision ECS and databases on Alibaba Cloud]()


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

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/luigi_metabase/images/data_pipeline.png)

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