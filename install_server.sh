#!/bin/bash

aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region "us-east-1" --instance-tenancy "default" --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=vpc_cms_webserver}]'
aws ec2 create-internet-gateway --region "us-east-1"  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=igw_cms_webserver}]'

aws ec2 attach-internet-gateway --internet-gateway-id "[InternetGatewayId]" --vpc-id "[VpcId]"

aws ec2 create-subnet --vpc-id [VpcId] --cidr-block 10.0.1.0/24 --region "us-east-1" --availability-zone "us-east-1e" --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=subnet_cms_webserver}]'
#route table weggelassen vorerst
#aws ec2 create-route-table --vpc-id [VpcId] --region "us-east-1" 
# key erstellen
aws ec2 create-key-pair --key-name cms_key --key-type rsa --query 'KeyMaterial' --output text > ~/.ssh/cms_key.pem
# security group 1 erstellen
aws ec2 create-security-group --group-name  cms-web-group --vpc-id [VpcId] --description "SSH and HTTP"
# security group 1 auf Ports autorisieren
aws ec2 authorize-security-group-ingress --group-name cms-sec-group --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name cms-sec-group --protocol tcp --port 22 --cidr 0.0.0.0/0
# security group 1 erstellen
aws ec2 create-security-group --group-name cms-db-group --vpc-id [VpcId] --description "SSH and HTTP"
# security group 2 auf Ports autorisieren
aws ec2 authorize-security-group-ingress --group-name cms-sec-group --protocol tcp --port 3306 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name cms-sec-group --protocol tcp --port 22 --cidr 0.0.0.0/0
# direcory für inital datei von webserver
mkdir ~/ec2cmswebserver
cd ~/ec2cmswebserver
# inital datei für webserverinstallation
touch initial.txt
echo "#!/bin/bash\nsudo apt-get update\nsudo apt-get -y install apache2" > initial.txt
# erstellen von EC2 instance
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --private-ip-adress 10.0.1.100 --security-groups cms-sec-group --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_webserver}]'
# direcory für inital datei von webserver
mkdir ~/ec2cmsdbserver
cd ~/ec2cmsdbserver
# inital datei für dbinstallation
touch initial.txt
echo "#!/bin/bash\nsudo apt-get update\nsudo apt-get -y install mariadb" > initial.txt
# erstellen von EC2 instance
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --private-ip-adress 10.0.1.200 --security-groups cms-sec-group --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_dataserver}]'

chmod 600 ~/.ssh/cms_key.pem