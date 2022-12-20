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
    echo 'sudo apt install -y mariadb-server'
    echo 'sudo apt install -y mariadb-client'
    echo 'sudo systemctl start mariadb.service'
    echo ''
    echo 'mysql -u root -p -e "CREATE USER 'wordpressusr'@'%' IDENTIFIED BY 'your_strong_password'";'
    echo 'mysql -u root -p -e "CREATE DATABASE `wordpress`;"'
    echo 'mysql -u root -p -e "GRANT ALL PRIVILEGES ON `wordpress`.* TO 'wordpressusr'@'%';"'
    echo 'mysql -u root -p -e "FLUSH PRIVILEGES;"'
} > initial.txt
#echo "#!/bin/bash\nsudo apt-get update\nsudo apt-get -y install mariadb-server\nsudo systemctl start mariadb.service" > initial.txt
# erstellen von EC2 instances
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile --user-data file://initial1.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_dataserver}]'
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=cms_dataserver" --query 'Reservations[*].Instances[*].InstanceId' --output text)
PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

# direcory für inital datei von webserver
mkdir ~/ec2cmswebserver
cd ~/ec2cmswebserver
# inital datei für webserverinstallation
touch initial.txt
sudo cat  << END > inital.txt
#!/bin/bash

sudo apt update
sudo apt install -y apache2

sudo apt install php php-mysql -y

wget https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz
sudo cp -R wordpress /var/www/html/
sudo chown -R www-data:www-data /var/www/html/wordpress/
sudo chmod -R 755 /var/www/html/wordpress/
sudo mkdir /var/www/html/wordpress/wp-content/uploads
sudo chown -R www-data:www-data /var/www/html/wordpress/wp-content/uploads/

cd /var/www/html
sudo touch wp-config.php
sudo cat << EOF > wp-config.php
<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */
 // ** Database settings - You can get this info from your web host ** //

/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** Database username */
define( 'DB_USER', 'wordpressusr' );

/** Database password */
define( 'DB_PASSWORD', 'your_secure_password' );

/** Database hostname */
define( 'DB_HOST', '$PRIVATE_IP' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );

/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
define( 'WP_DEBUG', false );
/* Add any custom values between this line and the "stop editing" line. */



/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
EOF
END


# erstellen von EC2 instance
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_webserver}]'
INSTANCE_ID2=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=cms_webserver" --query 'Reservations[*].Instances[*].InstanceId' --output text)
PRIVATE_IP2=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID2 --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

chmod 600 ~/.ssh/cms_key.pem

