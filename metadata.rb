name             'appserver'
maintainer       'Arvid Björkström'
maintainer_email 'arvid@bjorkstrom.se'
license          'MIT'
description      'Installs/Configures appserver'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'


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
depends 'database'
depends 'nginx' # https://github.com/phlipper/chef-nginx
