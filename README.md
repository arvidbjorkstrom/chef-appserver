# Appserver

## Description

Install and configure server for a modern php framework with nginx, php-fpm, MySQL and Opcache.
Made to play well with [vagrant-appserver](http://github.com/arvidbjorkstrom/vagrant-appserver)


## Requirements

### Supported Plattforms

The following platforms are supported by this cookbook, meaning that the
recipes should run on these platforms without error:

* Ubuntu 14.04

### Cookbooks

* [timezone-ii](http://community.opscode.com/cookbooks/timezone-ii) Cookbook by Lawrence Gilbert
* [apt](http://community.opscode.com/cookbooks/apt) Opscode LWRP Cookbook
* [zsh](http://community.opscode.com/cookbooks/zsh) Opscode LWRP Cookbook
* [git](http://community.opscode.com/cookbooks/git) Opscode LWRP Cookbook
* [chef-solo-search](https://supermarket.getchef.com/cookbooks/chef-solo-search) Cookbook by Markus Korn
* [users](http://community.opscode.com/cookbooks/users) Cookbook by Seth Vargo
* [oh-my-zsh](http://community.opscode.com/cookbooks/oh-my-zsh) Cookbook by Heavy Water Software
* [mysql](http://community.opscode.com/cookbooks/mysql) Opscode LWRP Cookbook
* [database](http://community.opscode.com/cookbooks/database) Opscode LWRP Cookbook
* [nginx](https://github.com/phlipper/chef-nginx) Cookbook by Phil Cohen
* [compass](https://github.com/arvidbjorkstrom/chef-compass) Cookbook by Arvid Björkström
* [swap](http://community.opscode.com/cookbooks/swap) Cookbook by Seth Vargo
* [nodejs](http://community.opscode.com/cookbooks/nodejs) Cookbook by Marius Ducea

### Chef

It is recommended to use a version of Chef `>= 11.12.4` as that is the target of my usage and testing, though it will probably work with older versions as well.

### Ruby

This cookbook requires Ruby 1.9+ and is tested against:

* 1.9.3
* 2.0.0
* 2.1.2


## Recipes

* `appserver` - Installs and configures the server via the internal recipes.
* `appserver::userconfig` - Internal recipe to do additional configuration of users
* `appserver::dbserver` - Internal recipe to setup mysql and import any supplied sql dump
* `appserver::webserver` - Internal recipe to setup php, php-fpm, composer and nginx.


## Usage

Nothing here yet.


## Attributes

```ruby

# Swap file, multiples of the server memory size
default['swapsize'] = 0

# Timezone
default['tz'] = 'Europe/Stockholm'

# MySQL
default['mysql']['server_root_username'] = 'root'
default['mysql']['server_root_password'] = 'YouShouldReplaceThis'
default['mysql']['server_debian_password'] = 'YouShouldReplaceThis'

default['mysql']['databases'] = [
  {
    'database' => 'dbname',
    'username' => 'dbuser',
    'password' => 'dbpass',
    'overwrite' => true
  }
]


# NGINX config and Site install & deploy
default['nginx']['sites'] = [
  {
    'name' => 'domain.se',
    'base_path' => '/var/www/domain.se',
    'host' => 'www.domain.se',
    'webroot_subpath' => 'public',
    'index' => 'index.php index.html index.htm',
    'location' => 'try_files $uri $uri/ /index.php?$query_string',
    'phpfpm' => true,
    'template_source' => 'serverblock.conf.erb',
    'template_cookbook' => 'appserver',
    'environment' => 'prod',
    'db_host' => 'localhost',
    'db_database' => 'dbname',
    'db_username' => 'dbuser',
    'db_password' => 'dbpass',
    'compass_compile' => true,
    'compass_subpath' => '',
    'artisan_migrate' => false,
    'artisan_subpath' => 'artisan',
    'composer_install' => true,
    'composer_subpath' => '',
    'npm_install' => true,
    'npm_subpath' => '',
    'bower_install' => true,
    'bower_subpath' => '',
    'gulp_run' => true,
    'gulp_subpath' => '',
    'git' => true,
    'git_subpath' => '',
    'git_repo' => 'git@bitbucket.org:gituser/domain.se.git',
    'git_branch' => 'master',
    'ssl' => true,
    'ssl_key' => '-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
',
    'ssl_crt' => '-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
',
    'writeable_dirs' => []
  }
]

# PHP
default['php']['error_reporting'] = 'E_ALL'
default['php']['display_errors'] = 'Off'
default['php']['log_errors'] = 'On'
default['php']['post_max_size'] = '96M'
default['php']['upload_max_filesize'] = '64M'
default['php']['max_file_uploads'] = '20'
default['php']['memory_limit'] = '256M'

# OPcache
default['opcache']['enabled'] = '1'
default['opcache']['memory_consumption'] = '128'
default['opcache']['interned_strings_buffer'] = '8'
default['opcache']['max_accelerated_files'] = '4000'
default['opcache']['revalidate_freq'] = '60'
default['opcache']['fast_shutdown'] = '1'
default['opcache']['enable_cli'] = '1'
default['opcache']['consistency_checks'] = '0'
```

## TODO

Nothing here yet.


## License

* Freely distributable and licensed under the [MIT license](http://arvid.mit-license.org/).
* Copyright (c) 2012-2014 Arvid Björkström (arvid@bjorkstrom.se) [![endorse](https://api.coderwall.com/arvidbjorkstrom/endorsecount.png)](https://coderwall.com/arvidbjorkstrom)
