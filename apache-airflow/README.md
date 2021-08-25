
Download and execute ``setup.sh``

```bash
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