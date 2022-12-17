#!/bin/bash

SUBNET_ID=$(aws ec2 describe-subnets --query "Subnets[?CidrBlock=='172.31.0.0/20'].SubnetId" --output text)

# key erstellen
aws ec2 create-key-pair --key-name cms_key --key-type rsa --query 'KeyMaterial' --output text > ~/.ssh/cms_key.pem
# security group 1 erstellen
aws ec2 create-security-group --group-name  cms-web-group --description "SSH and HTTP"
# security group 1 auf Ports autorisieren
aws ec2 authorize-security-group-ingress --group-name cms-sec-group --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name cms-sec-group --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name cms-sec-group --protocol tcp --port 3306 --cidr 0.0.0.0/0


# direcory für inital datei von webserver
mkdir ~/ec2cmsdbserver
cd ~/ec2cmsdbserver
# inital datei für dbinstallation
touch initial.txt
echo "#!/bin/bash\nsudo apt-get update\nsudo apt-get -y install mariadb-server\nsudo systemctl start mariadb.service" > initial.txt
# erstellen von EC2 instances
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --security-groups cms-sec-group --subnet-id $SUBNET_ID --private-ip-address 172.31.0.100 --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_dataserver}]'

# direcory für inital datei von webserver
mkdir ~/ec2cmswebserver
cd ~/ec2cmswebserver
# inital datei für webserverinstallation
touch initial.txt
echo "#!/bin/bash\nsudo apt-get update\nsudo apt-get -y install apache2" > initial.txt
# erstellen von EC2 instance
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --security-groups cms-sec-group --subnet-id $SUBNET_ID --private-ip-address 172.31.0.200 --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_webserver}]'

chmod 600 ~/.ssh/cms_key.pem


