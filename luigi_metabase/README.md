
Execute the following command to install gcc, python, related python modules, Luigi, JDK 8 and Git.

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
```

Then execute the following commands to install PostgreSQL client.

```
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

```
cd ~/opensource_with_apsaradb/luigi_metabase/metabase
wget https://downloads.metabase.com/v0.40.3.1/metabase.jar
java -jar metabase.jar
```

Admin User: admin@somebusiness.com
Password: N1cetest
Business Owner user: owner@somebusiness.com
Password: N1cetest

```
cd ~/adbpg_client_package/bin
./psql -hpgm-3nsa364dun8rza5k168190.pg.rds.aliyuncs.com -p1921 -Udemo sales_dw

\i ~/opensource_with_apsaradb/luigi_metabase/sales_dw_ddl.sql
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



This tutorial is modified based on [https://github.com/abhishekzambre/data-warehouse](https://github.com/abhishekzambre/data-warehouse) to running on Alibaba Cloud.