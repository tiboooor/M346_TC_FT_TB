#!/bin/bash

aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region "us-east-1" --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=vpc_cms_webserver}]'
aws ec2 create-internet-gateway --region "us-east-1" --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=igw_cms_webserver}]'


vpc_id=$(aws ec2 describe-vpcs --filter 'Name=cidrBlock,Values=10.0.0.0/16' --query 'Vpcs[*].{ID:VpcId}' --output text)
igw_id=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=igw_cms_webserver" --query 'InternetGateways[*].InternetGatewayId' --output text)

aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id

aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.1.0/24 --region "us-east-1" --availability-zone "us-east-1e" --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=subnet_cms_webserver}]'
subnet_id=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=subnet_cms_webserver --query 'Subnets[*].SubnetId' --output text)
#route table weggelassen vorerst
#aws ec2 create-route-table --vpc-id $vpc_id --region "us-east-1" 
# key erstellen
aws ec2 create-key-pair --key-name cms_key --key-type rsa --query 'KeyMaterial' --output text > ~/.ssh/cms_key.pem
# security group  erstellen
aws ec2 create-security-group --group-name sec-group-cms --vpc-id $vpc_id --description "SSH and HTTP and 3306"
sec_id=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" "Name=group-name,Values=sec-group-cms" --query 'SecurityGroups[*].{ID:GroupId}' --output text)

# security group  auf Ports autorisieren
aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol tcp --port 3306 --cidr 0.0.0.0/0


# direcory für inital datei von webserver
mkdir ~/ec2cmsdbserver
cd ~/ec2cmsdbserver
# inital datei für dbinstallation
touch initial.txt
echo "#!/bin/bash\nsudo apt-get update\nsudo apt-get -y install mariadb-server\nsudo systemctl start mariadb.service" > initial.txt
# erstellen von EC2 instances
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --private-ip-address 10.0.1.20 --subnet-id $subnet_id --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_dataserver}]'

# direcory für inital datei von webserver
mkdir ~/ec2cmswebserver
cd ~/ec2cmswebserver
# inital datei für webserverinstallation
touch initial.txt
echo "#!/bin/bash\nsudo apt-get update\nsudo apt-get -y install apache2" > initial.txt
# erstellen von EC2 instance
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --private-ip-address 10.0.1.10 --subnet-id $subnet_id --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_webserver}]'

chmod 600 ~/.ssh/cms_key.pem