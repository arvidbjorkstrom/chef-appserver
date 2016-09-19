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
default['mysql']['databases'] = []


# NGINX
default['nginx']['sites'] = []

# PHP
# Default Value: E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED
# Development Value: E_ALL
# Production Value: E_ALL & ~E_DEPRECATED & ~E_STRICT
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

# Node
default['nodejs']['install_method'] = 'source'
# default["nodejs"]["version"] = "4.2.4"
# default['nodejs']['source']['checksum'] = "4ee244ffede7328d9fa24c3024787e71225b7abaac49fe2b30e68b27460c10ec"
# default["nodejs"]["npm"]["install_method"] = "source"
```

## TODO

Nothing here yet.


## License

* Freely distributable and licensed under the [MIT license](http://arvid.mit-license.org/).
* Copyright (c) 2012-2014 Arvid Björkström (arvid@bjorkstrom.se) [![endorse](https://api.coderwall.com/arvidbjorkstrom/endorsecount.png)](https://coderwall.com/arvidbjorkstrom)
