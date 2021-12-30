# Quick Path to Build BI Dashboard with Cube, React and RDS PostgreSQL

You can access the tutorial artifact including deployment script (Terraform), related source code, sample data and instruction guidance from the github project:
https://github.com/alibabacloud-howto/opensource_with_apsaradb/tree/main/cubejs/postgresql

More tutorial around Alibaba Cloud Database, please refer to:
[https://github.com/alibabacloud-howto/database](https://github.com/alibabacloud-howto/database)

---
### Overview

[Cube](https://cube.dev/) is the headless API layer that connects cloud data warehouses to your front end code so you can build data applications faster.

In this solution tutorial, let's see how to build a BI Dashboard with Cube, React and  [RDS for PostgreSQL](https://www.alibabacloud.com/product/apsaradb-for-rds-postgresql) on Alibaba Cloud.

Deployment architecture of this tutorial:

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/postgresql/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS and RDS for PostgreSQL database on Alibaba Cloud]()
- [Step 2. Configure and deploy Data API on Cube]()
- [Step 3. Configure and deploy React Dashboard]()

---
### Step 1. Use Terraform to provision ECS and RDS for PostgreSQL database on Alibaba Cloud

If you are the 1st time to use Terraform, please refer to [https://github.com/alibabacloud-howto/terraform-templates](https://github.com/alibabacloud-howto/terraform-templates) to learn how to install and use the Terraform on different operating systems.

Run the [terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/cubejs/postgresql/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use 1 ECS to deploy Cube and 1 RDS for PostgreSQL instance as the backend database). Please specify the necessary information and region to deploy.

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/tf-parms.png)

After the Terraform script execution finished, the ECS instance and RDS for MySQL information are listed as below.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/postgresql/images/tf-done.png)

- ``eip_ecs``: The public EIP of the ECS for cube server and dashboard frontend app host
- ``rds_pg_port``: The RDS for PostgreSQL database instance service port
- ``rds_pg_url``: The RDS for PostgreSQL database instance connection URL

BTW, we use the Terraform provisioner ``remote-exec`` to prepare and setup all the necessary components and sample data all in a single [Terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/cubejs/postgresql/deployment/terraform/main.tf).

---
### Step 2. Configure and deploy Data API on Cube

Please log on to ECS with ``ECS EIP``. By default, the password is ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>
```

Execute the commands to edit the docker configuration file to configure the database with the RDS for PostgreSQL instance.

```
cd ~/cube.js/examples/react-dashboard
vim docker-compose.yml
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/postgresql/images/docker_config.png)

Replace the ``CUBEJS_DB_HOST`` value with the ``rds_pg_url`` in Step 1. Then execute the following command to start the Cube server.

```
docker-compose up
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/postgresql/images/cube-start.png)

Then visit the URL ``<ECS_EIP>:4000`` in browser, you will see the ``Cube playground``. Please set ``Schema``, and all tables under ``public``, then click ``Generate Schema`` to generated Cube schema files.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/postgresql/images/cube-web-1.png)

Then click ``Close`` button on the prompted window.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/postgresql/images/cube-web-2.png)

---
### Step 3. Configure and deploy React Dashboard

Please log on to ECS with ``ECS EIP`` on another command line window. By default, the password is ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>
```

Then execute the following commands to configure the React dashboard to connect to the Cube data API deployed in Step 2.

```
cd ~/cube.js/examples/react-dashboard/dashboard-app
cp .env.development .env
vim .env
```

Edit to replace the ``localhost`` with ``eip_ecs`` in Step 1 and save.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/postgresql/images/react-config.png)

Then run the commands to start the React dashboard app.

```
npm install
npm start
```

Then visit the URL ``<ECS_EIP>:3000`` in browser, you will see the dashboard.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/cubejs/postgresql/images/dashboard.png)