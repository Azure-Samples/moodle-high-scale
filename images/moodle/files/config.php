<?php  // Moodle configuration file

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'pgsql';
$CFG->dblibrary = 'native';
$CFG->dbhost    = '$DATABASE_HOST';
$CFG->dbname    = '$DATABASE_NAME';
$CFG->dbuser    = '$DATABASE_USER';
$CFG->dbpass    = '$DATABASE_PASSWORD';
$CFG->prefix    = '$DATABASE_PREFIX';
$CFG->dboptions = array (
  'dbpersist' => true,
  'dbport' => $DATABASE_PORT,
  'dbsocket' => false,
  'dbhandlesoptions' => true,
  'fetchbuffersize' => 0,
  'readonly' => [
    'instance' => '$DATABASE_HOST_READ',
    'connecttimeout' => 2,
    'latency' => 0.5,
  ]
);

$CFG->wwwroot   = '$WWW_ROOT';
$CFG->dataroot  = '$DATA_ROOT';
$CFG->admin     = '$ADMIN';

$CFG->localcachedir               = '/var/www/localdata/cache';
$CFG->alternative_component_cache = '/var/www/localdata/cache/core_component.php';
$CFG->localrequestdir             = '/var/www/localdata/request';

$CFG->alternative_file_system_class = '\tool_objectfs\azure_file_system';

$CFG->directorypermissions = 02777;

$CFG->sslproxy  = $SSL_PROXY;

$CFG->session_handler_class = '\cachestore_rediscluster\session';
$CFG->session_rediscluster = [
    'server' => '$REDIS_SESSION_HOST:$REDIS_SESSION_PORT',
    'prefix' => "mdlsession_{$CFG->dbname}:",
    'acquire_lock_timeout' => 60,
    'lock_expire' => 600,
    'max_waiters' => 10,
    #'auth' => '$REDIS_SESSION_AUTH',
];

$CFG->xsendfile = 'X-Accel-Redirect';

$CFG->xsendfilealiases = array(
  '/dataroot/' => $CFG->dataroot,
  '/localcachedir/' => $CFG->localcachedir,
);

require_once(__DIR__ . '/lib/setup.php');

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!