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
cat > initial.txt << LAH
#!/bin/bash

sudo apt update
sudo apt install -y mariadb-server
sudo apt install -y mariadb-client
sudo systemctl start mariadb.service
sudo sed 's/bind-address            = 127.0.0.1/#bind-address            = 127.0.0.1/' /etc/mysql/mariadb.conf.d/50-server.cnf
touch commands.sql
sudo chmod 777 commands.sql
cat > commands.sql << WAHM
DROP USER 'wordpressust'@'%';
FLUSH PRIVILEGES;
CREATE USER 'wordpressusr'@'%' IDENTIFIED BY 'your_strong_password';
CREATE DATABASE `wordpress`;
GRANT ALL PRIVILEGES ON `wordpress`.* TO 'wordpressusr'@'%';
FLUSH PRIVILEGES;
WHAM
sudo mysql -u root -p mysql > commands.sql
# sudo mysql -u root -p -e "CREATE USER 'wordpressusr'@'%' IDENTIFIED BY 'your_strong_password';"
# sudo mysql -u root -p -e "CREATE DATABASE wordpress;"
# sudo mysql -u root -p -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpressusr'@'%';"
# sudo mysql -u root -p -e "FLUSH PRIVILEGES;"
LAH
# erstellen von EC2 instances
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_dataserver}]'
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=cms_dataserver" --query 'Reservations[*].Instances[*].InstanceId' --output text)
PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

# direcory für inital datei von webserver
mkdir ~/ec2cmswebserver
cd ~/ec2cmswebserver
# initial datei für webserverinstallation
touch initial.txt
table_prefix='$table_prefix'
cat > initial.txt << END 
#!/bin/bash

sudo apt update
sudo apt install -y apache2

sudo apt install php php-mysql -y
sudo apt install mysql-client -y

wget https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz
sudo cp -R wordpress /var/www/
sudo chown -R www-data:www-data /var/www/wordpress/
sudo chmod -R 755 /var/www/wordpress/
sudo mkdir /var/www/wordpress/wp-content/uploads
sudo chown -R www-data:www-data /var/www/wordpress/wp-content/uploads/
table_prefix='$table_prefix'

cd /var/www/wordpress
sudo touch wp-config.php
sudo cat > wp-config.php << EOF
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
define( 'AUTH_KEY',         '8osX70IonLV3A9Mlu0WVg0oGLzz5MgJMpHVz8zitckP1SsteKXHxqY1fXpvaJwlk' );
define( 'SECURE_AUTH_KEY',  'pSoIDaYURWoYUD8RTBv1kCgv3jorJABv9EKpufdsNrJhNRPhOaeIyLmHQ1w83b1k' );
define( 'LOGGED_IN_KEY',    'ZyKbAhQBspTJqXhAZuDMiuFDZWv3ggXT10PTaQwaiyhRGDde6rcCflgmiBjEftHk' );
define( 'NONCE_KEY',        'laInXuVinVfGvJu4NmNGIQyLunXcI7lmpOAacxH4DY679AK2uBxG5ImsY9SRCW0E' );
define( 'AUTH_SALT',        'vQGSNyXiR6N4CGHWg7wYkM8o9u7cD3iVyNHyhfimqQd7lwpJiHrWEBTQb7VNVJtY' );
define( 'SECURE_AUTH_SALT', '6jtnSkO6yi4mhyqkyAVWx41rNNtgZ2igStAxriOjZR6uZE75AFLzHtwnGwJR3s6Q' );
define( 'LOGGED_IN_SALT',   'fp4Fu1qtu2ng0rb2vmDTqMUCsxQgyrc26V9SPKjwlmxDZF6doQ2gHppzGABrcQ1W' );
define( 'NONCE_SALT',       'KXyKEi1lnLAQBOPUTu0TFreTELb65H5PmnophtDZTZdeFaphfgxMRsb44iq08sGW' );

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
sudo chmod 755 wp-config.php
cd /etc/apache2/sites-available
sudo touch wordpress.conf
sudo chmod 666 wordpress.conf
sudo cat > wordpress.conf << FOO
<VirtualHost *:80>
        DocumentRoot /var/www/wordpress
</VirtualHost>
FOO
sudo a2ensite wordpress.conf
sudo a2dissite 000-default.conf
sudo systemctl restart apache2
END


# erstellen von EC2 instance
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_webserver}]'

chmod 600 ~/.ssh/cms_key.pem

