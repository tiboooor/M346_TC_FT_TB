#!/bin/bash

# key erstellen
aws ec2 create-key-pair --key-name cms_key --key-type rsa --query 'KeyMaterial' --output text > ~/.ssh/cms_key.pem
# security group  erstellen
aws ec2 create-security-group --group-name sec-group-cms --description "SSH and HTTP and 3306"
sec_id=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=sec-group-cms" --query 'SecurityGroups[*].{ID:GroupId}' --output text)

# security group  auf Ports autorisieren
aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol tcp --port 3306 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol icmp --port -1 --cidr 0.0.0.0/0


# direcory für inital datei von webserver
mkdir ~/ec2cmsdbserver
cd ~/ec2cmsdbserver
# inital datei für dbinstallation
touch initial.txt
{
    echo '#!/bin/bash'
    echo ''
    echo 'sudo apt update'
    echo 'sudo apt install mariadb-server -y'
    echo 'sudo systemctl start mariadb.service'
    echo ''
    echo 'mysql -u root -p -e "CREATE USER 'wordpressusr'@'%' IDENTIFIED BY 'your_strong_password'";'
    echo 'mysql -u root -p -e "CREATE DATABASE `wordpress`;"'
    echo 'mysql -u root -p -e "GRANT ALL PRIVILEGES ON `wordpress`.* TO 'wordpressusr'@'%';"'
    echo 'mysql -u root -p -e "FLUSH PRIVILEGES;"'
    echo ''
    echo ''
    echo ''
} >> initial.txt
#echo "#!/bin/bash\nsudo apt-get update\nsudo apt-get -y install mariadb-server\nsudo systemctl start mariadb.service" > initial.txt
# erstellen von EC2 instances
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_dataserver}]'
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=cms_dataserver" --query 'Reservations[*].Instances[*].InstanceId' --output text)
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

# direcory für inital datei von webserver
mkdir ~/ec2cmswebserver
cd ~/ec2cmswebserver
# inital datei für webserverinstallation
touch initial.txt
echo "#!/bin/bash\nsudo apt-get update\nsudo apt-get -y install apache2" > initial.txt
# erstellen von EC2 instance
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_webserver}]'
INSTANCE_ID2=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=cms_webserver" --query 'Reservations[*].Instances[*].InstanceId' --output text)
PUBLIC_IP2=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID2 --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

chmod 600 ~/.ssh/cms_key.pem
