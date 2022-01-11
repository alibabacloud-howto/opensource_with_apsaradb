
---
### Step 2. Load sample data into MongoDB and start MongoDB Connector for BI process

Please log on to ECS with ``ECS EIP``. By default, the password is ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>
```

Execute the commands to generate key for SSL when using ``MongoDB Connector for BI`` tool ``mongodbsqld``.

```
openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out certificate.pem
cat key.pem certificate.pem > mongo.pem
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/mongodb/images/ssl-key.png)

Then execute the command to load the sample data into the MongoDB, please replace the ``<MONGO_URL_DOMAIN>`` with the MongoDB connection domain in Step 1. Such as, 
``mongorestore -h dds-xxxxx1.mongodb.rds.aliyuncs.com:3717,dds-xxxxx2.mongodb.rds.aliyuncs.com:3717 -u root -p N1cetest dump/stats/events.bson``

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/mongodb/images/mongo_connect_domain.png)

```
cd ~/cube.js/examples/real-time-dashboard
mongorestore -h <MONGO_URL_DOMAIN>:3717,<MONGO_URL_DOMAIN>:3717 -u root -p N1cetest dump/stats/events.bson
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/mongodb/images/mongo_sample_data.png)

Then execute the command to start the ``MongoDB Connector for BI``, please replace the ``<ECS_PRIVATE_IP>`` with the ``eip_ecs_private_ip`` and the ``<MONGO_URL_DOMAIN>`` with the MongoDB connection domain in Step 1. Such as,
``mongodb-bi-linux-x86_64-ubuntu2004-v2.14.4/bin/mongosqld --addr 192.168.0.95:3307 --mongo-uri dds-xxxxx1.mongodb.rds.aliyuncs.com:3717,dds-xxxxx2.mongodb.rds.aliyuncs.com:3717 --mongo-username=root --mongo-password=N1cetest --auth --sslMode requireSSL --sslPEMKeyFile mongo.pem``

```
cd ~
mongodb-bi-linux-x86_64-ubuntu2004-v2.14.4/bin/mongosqld --addr <ECS_PRIVATE_IP>:3307 --mongo-uri <MONGO_URL_DOMAIN>:3717,<MONGO_URL_DOMAIN>:3717 --mongo-username=root --mongo-password=N1cetest --auth --sslMode requireSSL --sslPEMKeyFile mongo.pem
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/mongodb/images/mongobi_start.png)

Now, the ``MongoDB Connector for BI`` process has started successfully.

---
### Step 3. Configure and deploy Data API on Cube

Please log on to ECS with ``ECS EIP`` on another command line window. By default, the password is ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>
```

Execute the commands to edit the docker configuration file to configure the database with the MongoDB Connector for BI and the MongoDB instance.

```
cd ~/cube.js/examples/real-time-dashboard/
vim docker-compose.yml
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/mongodb/images/docker_config.png)

Replace the ``CUBEJS_DB_HOST`` value with the ``eip_ecs_public_ip`` in Step 1. Then execute the following command to start the Cube server.

```
docker-compose up
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/mongodb/images/cube-start.png)

Then visit the URL ``<ECS_EIP>:4000`` in browser, you will see the ``Cube playground``.

---
### Step 4. Configure and deploy the real-time dashboard

Please log on to ECS with ``ECS EIP`` on another command line window. By default, the password is ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>
```

Then execute the following commands to configure the React dashboard to connect to the Cube data API deployed in Step 2.

```
cd ~/cube.js/examples/real-time-dashboard/dashboard-app
cp .env.development .env
vim .env
```





export LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN=1
mysql -h<ECS_EIP> --protocol=tcp --port=3307 -uroot -pN1cetest




