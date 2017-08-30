name             'appserver'
maintainer       'Arvid Bjorkstrom'
maintainer_email 'arvid@bjorkstrom.se'
license          'MIT'
description      'Installs/Configures appserver'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.0.0'


recipe 'appserver', 'Installs and configures the server via internal recipes.'
recipe 'appserver::dbserver', 'Internal recipe to setup mysql.'
recipe 'appserver::webserver', 'Internal recipe to setup php-fpm and nginx.'

depends 'timezone-ii'
depends 'apt', '~>2.6.1'
depends 'ark', '~>2.0.0'
depends 'zsh', '~>1.0.1'
depends 'git', '~>4.1.0'
depends 'chef-solo-search', '~>0.5.1'
depends 'users', '~>1.7.0'
depends 'sudo', '~>2.7.1'
depends 'oh-my-zsh', '~>0.4.3'
depends 'mysql', '~> 8.0'
depends 'mysql2_chef_gem', '~> 1.1.0'
depends 'automysqlbackup', '~> 2.0.1'
depends 'nginx' # https://github.com/phlipper/chef-nginx
depends 'compass' # https://github.com/phlipper/chef-nginx
depends 'swap', '~> 0.3.8'
depends 'nodejs', '~> 2.4.0'
depends 'redisio', '~> 2.3.0'
depends 'supervisor', '~> 0.4.12'
depends 'unattended-upgrades', '~> 0.1.2'
