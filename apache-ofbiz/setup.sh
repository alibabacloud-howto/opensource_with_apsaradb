#!/bin/sh

# Install GIT
yum install -y git

# Install JDK 1.8
yum install -y java-1.8.0-openjdk-devel.x86_64

# Clone OFBIZ project from GITHUB
git clone https://gitbox.apache.org/repos/asf/ofbiz-framework.git ofbiz-framework

# Download MySQL JDBC driver
wget https://downloads.mysql.com/archives/get/p/3/file/mysql-connector-java-5.1.49.tar.gz
tar xvf mysql-connector-java-5.1.49.tar.gz
cp mysql-connector-java-5.1.49/mysql-connector-java-5.1.49-bin.jar ofbiz-framework/lib/
