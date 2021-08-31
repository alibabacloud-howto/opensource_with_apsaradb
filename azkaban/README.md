Install JDK 8 and Git. Then download Azkaban project from github.

```
# Install GCC, JDK 8, Git and MySQL client.
yum install -y gcc-c++*
yum install -y java-1.8.0-openjdk-devel.x86_64
yum install -y git
yum install -y mysql.x86_64

yum install -y python39
yum install -y postgresql-devel
pip3 install psycopg2


```bash
cd ~
wget http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/compat-openssl10-1.0.2o-3.el8.x86_64.rpm
rpm -i compat-openssl10-1.0.2o-3.el8.x86_64.rpm
wget http://docs-aliyun.cn-hangzhou.oss.aliyun-inc.com/assets/attach/181125/cn_zh/1598426198114/adbpg_client_package.el7.x86_64.tar.gz
tar -xzvf adbpg_client_package.el7.x86_64.tar.gz
```


# Download Azkaban project from github

```
cd ~
git clone https://github.com/azkaban/azkaban.git
```

# Build without running tests

```
cd ~/azkaban
./gradlew clean
./gradlew build installDist -x test
```


Build module ``azkaban-db``, and create all tables needed for Azkaban.

```
cd ~/azkaban/azkaban-db; ../gradlew build installDist -x test
```

```
cd ~/azkaban/azkaban-db/build/distributions
unzip azkaban-db-*.zip

mysql -hrm-3nssusij8bbe3a9c3.mysql.rds.aliyuncs.com -P3306 -uazkaban -pN1cetest azkaban < ~/azkaban/azkaban-db/build/distributions/azkaban-db-*/create-all-sql-*.sql
mysql -hrm-3nssusij8bbe3a9c3.mysql.rds.aliyuncs.com -P3306 -uazkaban -pN1cetest azkaban

show tables;
```

Install Azkaban Executor Server:

```
cd ~/azkaban/azkaban-exec-server; ../gradlew build installDist -x test
vim ~/azkaban/azkaban-exec-server/build/install/azkaban-exec-server/conf/azkaban.properties
```

Please refer to [https://docs.oracle.com/javase/8/docs/api/java/time/ZoneId.html](https://docs.oracle.com/javase/8/docs/api/java/time/ZoneId.html) for the ``default.timezone.id``

```
cd ~/azkaban/azkaban-web-server; ../gradlew build installDist -x test
vim ~/azkaban/azkaban-web-server/build/install/azkaban-web-server/conf/azkaban.properties
```

``azkaban.executorselector.filters=StaticRemainingFlowSize,MinimumFreeMemory,CpuStatus`` MUST be replaced with ``azkaban.executorselector.filters=StaticRemainingFlowSize,CpuStatus`` to remove the parameter ``MinimumFreeMemory``.
The web server will check whether the free memory of the executor host will be greater than ``6G``, if it is less than ``6G``, the web server will not hand over the task to the executor host for execution. Since in our tutorial, we use entry level ECS with small memory less than ``6G``, we need to remove this parameter to make the task work.

Azkaban web server user account is configured within the following file.

```
vim ~/azkaban/azkaban-web-server/build/install/azkaban-web-server/conf/azkaban-users.xml
```

```
cd ~/azkaban/azkaban-exec-server/build/install/azkaban-exec-server
./bin/start-exec.sh
```

```
curl -G "localhost:$(<./executor.port)/executor?action=activate" && echo
```

```
cd ~/azkaban/azkaban-web-server/build/install/azkaban-web-server
./bin/start-web.sh
```

Then, a multi-executor Azkaban instance is ready for use. Open a web browser and check out ``http://<ECS_EIP>:8081/`` You are all set to login to Azkaban UI with username ``azkaban`` and password ``azkaban``.

In the local computer, checkout the project to local from github.

```
git clone https://github.com/alibabacloud-howto/opensource_with_apsaradb.git
cd opensource_with_apsaradb/azkaban/project-demo

```

Edit the Azkaban project files accordingly for connecting to the target RDS PostgreSQL demo database. 


Package all the project files to zip.

```
zip -q -r project_demo_northwind.zip *
```



```
cd ~/adbpg_client_package/bin
./psql -hpgm-3ns0ylsmq3424hzs168190.pg.rds.aliyuncs.com -p1921 -Udemo northwind_source
select tablename from pg_tables where schemaname='public';
select count(*) from products;
select count(*) from orders;
```

```
cd ~/adbpg_client_package/bin
./psql -hpgm-3ns0ylsmq3424hzs168190.pg.rds.aliyuncs.com -p1921 -Udemo northwind_target
select tablename from pg_tables where schemaname='public';
select count(*) from products;
select count(*) from orders;
```