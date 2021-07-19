# Deploy and Running Superset on Alibaba Cloud
Running open source project Apache Superset on Alibaba Cloud with ApsaraDB (Alibaba Cloud Database).

---
### Overview
[Superset (https://superset.apache.org/)](https://superset.apache.org/) is a modern data exploration and visualization platform.
To enhance with the database high availability behind the Superset data exploration and visualization, we will show the steps of deployment working with Alibaba Cloud Database Family.

In this tutorial, we will use the [Superset image](https://marketplace.alibabacloud.com/products/56698003/Apache_em_Superset_em_on_Ubuntu-sgcmjj00025684.html) in Alibaba Cloud Marketplace, which is well packaged and configured for easy starting and future version upgrading.
For more administration guide of this Superset image, please refer to: https://support.websoft9.com/docs/superset

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/netflix_dispatch/images/deployment.png)

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/netflix_dispatch/images/deployment.png)

---
### Index

- [Step 1. Use Terraform to provision ECS image and database on Alibaba Cloud]()
- [Step 2. Setup connection to RDS PostgreSQL]()

---
### Step 1. Use Terraform to provision ECS image and database on Alibaba Cloud

Run the [terraform script](https://github.com/alibabacloud-howto/solution-marketplace-wordpress/blob/master/deployment/terraform/0_wordpress/main.tf) to initialize the resources. 
Within the terraform script, please use the right ``Image ID`` of [WordPress image on the corresponding region](https://marketplace.alibabacloud.com/products/56720001/WP_CMS_on_LAMP-sgcmjj00025386.html).

![image.png](https://github.com/alibabacloud-howto/solution-marketplace-wordpress/raw/master/images/phase0_1.png)

![image.png](https://github.com/alibabacloud-howto/solution-marketplace-wordpress/raw/master/images/phase0_2.png)

After the Terraform script execution, open the following URL in a Web browser to initialize WordPress: 

```bash
http://<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/solution-marketplace-wordpress/raw/master/images/phase0_3.png)

---
### Step 2. Setup connection to RDS PostgreSQL


``postgresql://superset:superset@pgm-gs5n44yc841r4y5y70490.pgsql.singapore.rds.aliyuncs.com:1921/superset``

https://docs.sqlalchemy.org/en/13/core/engines.html
