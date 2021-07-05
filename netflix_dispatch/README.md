# Deploy and Running Netflix Dispatch on Alibaba Cloud
Running open source project Netflix Dispatch on Alibaba Cloud with ApsaraDB (Alibaba Cloud Database).

---
### Overview
[Dispatch (https://github.com/Netflix/dispatch)](https://github.com/Netflix/dispatch) is an open source project from Netflix for managing incidents.
Dispatch docker image depends on an open source PostgreSQL by default. To enhance with the database high availability, we will show the steps of deployment working with Alibaba Cloud RDS PostgreSQL.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/netflix_dispatch/images/deployment.png)

---
### Index

- []()
- []()
- []()
- []()

---
### Step 1. Use Terraform to provision ECS and database on Alibaba Cloud

Follow this guide (https://www.alibabacloud.com/help/doc-detail/91289.html) to install and configure the Terraform client. Please skip this step if you have already setup the Terraform on your environment.

Use terraform to provision EIP, ECS and RDS PostgreSQL instances that used in this solution against this .tf file: https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/netflix_dispatch/deployment/terraform/main.tf

![image.png]()

---
### Step 2. Setup docker and git

Logon to ECS via SSH, use the account root/N1cetest, the password has been predefined in Terraform script for this tutorial. If you changed the password, please use the correct password accordingly.

```
ssh root@<EIP_ECS>
```

Download the run the setup script ``setup.sh`` to setup docker and git client on ECS.

```
wget https://raw.githubusercontent.com/alibabacloud-howto/opensource_with_apsaradb/main/netflix_dispatch/setup.sh
```

```
sh setup.sh
```

![image.png]()

---
### Step 3. Setup RDS PostgreSQL as database for Dispatch

Run the following commands and edit the ``.env`` file with RDS PostgreSQL connection information.

```
cd dispatch-docker
mv .env.example .env
vim .env
```

![image.png]()

---
### Step 4. Install and run Dispatch

```
./install.sh
```

![image.png]()

```
docker-compose up -d
```

```
http://<ECS_EIP>:8000
```

![image.png]()
