
# ===============================
# DRAFT - just some initial ideas
# ================================


rm composer.json

# check / install composer
composer create-project --no-interaction "drupal/recommended-project:^9" ./
composer require drush/drush
composer require vlucas/phpdotenv

chown -R www-data:www-data web/sites web/modules web/themes

# test if exists
cat > .env << EOF
DB_DRIVER=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=
DB_NAME=
DB_PASSWORD=
DRUPAL_HASH_SALT=$(drush eval 'echo \Drupal\Component\Utility\Crypt::randomBytesBase64(55);')
EOF

cat > load.environment.php << EOF
<?php

use Dotenv\Dotenv;

\$dotenv = Dotenv::createUnsafeImmutable(__DIR__);
\$dotenv->safeLoad();
EOF

cp -f web/sites/default/default.settings.php web/sites/default/settings.php

cat >> web/sites/default/settings.php << EOF
if (file_exists(__DIR__ . '/settings.dev.php')) {
  include __DIR__ . '/settings.dev.php';
}
else {
  include __DIR__ . '/settings.prod.php';
}
EOF

cat > web/sites/default/settings.dev.php << EOF
<?php

\$config_sync_dir = '../config/sync';

\$db_driver = getenv('DB_DRIVER');
\$host = getenv('DB_HOST');
\$port = getenv('DB_PORT');
\$db_user = getenv('DB_USER');
\$db_name = getenv('DB_NAME');
\$db_pass = getenv('DB_PASSWORD');

\$databases['default']['default'] = array(
  'database' => \$db_name,
  'username' => \$db_user,
  'password' => \$db_pass,
  'host' => \$host,
  'driver' => \$db_driver,
  'port' => \$port,
  'prefix' => "",
);

\$settings['hash_salt'] = getenv('DRUPAL_HASH_SALT');

// This will prevent Drupal from setting read-only permissions on sites/default.
\$settings['skip_permissions_hardening'] = TRUE;

// This will ensure the site can only be accessed through the intended host
// names. Additional host patterns can be added for custom configurations.
\$settings['trusted_host_patterns'] = ['.*'];

// Don't use Symfony's APCLoader. ddev includes APCu; Composer's APCu loader has
// better performance.
\$settings['class_loader_auto_detect'] = FALSE;

// For Drupal9, it's always $settings['config_sync_directory']
if (version_compare(DRUPAL::VERSION, "9.0.0", '>=') &&
  empty(\$settings['config_sync_directory'])) {
  \$settings['config_sync_directory'] = \$config_sync_dir;
}
EOF


drush site:install -y

#GRANT ALL PRIVILEGES ON site_db.* TO 'db_user'@'localhost';
#FLUSH PRIVILEGES;

# composer.json
#    "autoload": {
#        "files": ["load.environment.php"]
#    },


chmod ugo-w web/sites/default/settings.php
chmod ugo-w web/sites/default/settings.dev.php
chmod ugo-w web/sites/default/settings.prod.php
