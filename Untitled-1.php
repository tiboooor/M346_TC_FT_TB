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
define( 'DB_PASSWORD', 'your_strong_password' );

/** Database hostname */
define( 'DB_HOST', '$PRIVATE_IP2' );

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
define('AUTH_KEY',         '1J2_}1/}AS$-+{q{sz[o2I3#A/:10l;zJ)57gmO?Yk}j^SK`,wP!9e;r>_VDl=i-');
define('SECURE_AUTH_KEY',  'H@%MdqyK7mG(L@B$&(U;R*t4-o<*8f37 blqS1C+S{ha4XY%wGIb,wrD(4SNN$[a');
define('LOGGED_IN_KEY',    '4F+to!{~9pB{-O)(Qjj[Byi~VzzSlnG@yO>JQ~-+&Y%/1&p 0Hx9kC}v|=FU? -4');
define('NONCE_KEY',        '|UkjQj4}CM?D/wwH@s~Nli,xo27BI3u]PvLs(nnh.Yh@2S`8trT}Jsep{,ycdw1:');
define('AUTH_SALT',        '_#@|c+wK](xQsodH/z*cr:YE%5-4oM3CC|-T|+Aj]%323]C:)T^6mc:p$GEB5#@1');
define('SECURE_AUTH_SALT', 'O@/V*A*}xb4U#1,SX<q?Uau@bE]C=!b=W!E2 Mq9]N-X$|]nQ*L`*-e=(B-sF-z@');
define('LOGGED_IN_SALT',   'j*QEi8PV|$Lc5b?#-Po>;#v5pDL58`BH>+;ZZ}UU^pL|mx`9+PpLd-5]iJ&zZw~`');
define('NONCE_SALT',       'U{J+:u.NJQjJD!PpT]Y[U~vl_o&:GYS{+cUx9UjB[-+#pE1o[,w`I$/g@mb0VQij');

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