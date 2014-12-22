name             'appserver'
maintainer       'Arvid Bjorkstrom'
maintainer_email 'arvid@bjorkstrom.se'
license          'MIT'
description      'Installs/Configures appserver'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.1.1'


recipe 'appserver', 'Installs and configures the server via internal recipes.'
recipe 'appserver::dbserver', 'Internal recipe to setup mysql.'
recipe 'appserver::webserver', 'Internal recipe to setup php-fpm and nginx.'

depends 'timezone-ii'
depends 'apt'
depends 'zsh'
depends 'git'
depends 'chef-solo-search'
depends 'users'
depends 'sudo'
depends 'oh-my-zsh'
depends 'mysql', '~>5.4.4'
depends 'mysql-chef_gem', '~>0.0.5'
depends 'database'
depends 'nginx' # https://github.com/phlipper/chef-nginx
depends 'compass' # https://github.com/phlipper/chef-nginx
