#
# Cookbook Name:: appserver
# Recipe:: webserver
#

# PHP FPM
package 'php5-fpm' do
  action :install
end

service 'php-fpm' do
  provider ::Chef::Provider::Service::Upstart
  service_name 'php5-fpm'
  supports enable: true, start: true, stop: true, restart: true
  # :reload doesnt work on ubuntu 14.04 because of a bug...
  action [:enable, :start]
end

# PHP with plugins
%w(php5 php5-cli php5-mysql php5-curl php5-mcrypt php5-gd imagemagick php5-imagick).each do |pkg| # rubocop:disable LineLength
  package pkg do
    action :install
  end
end

template '/etc/php5/fpm/php.ini' do
  source 'php.ini.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[php-fpm]'
end

template '/etc/php5/mods-available/opcache.ini' do
  source 'opcache.ini.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[php-fpm]'
end

execute 'Enable Mcrypt' do
  command 'php5enmod mcrypt'
  action :run
  notifies :restart, 'service[php-fpm]'
end


execute 'Install Composer' do # ~FC041
  command 'curl -sS https://getcomposer.org/installer | php;mv composer.phar /usr/local/bin/composer' # rubocop:disable LineLength
  not_if { ::File.exist?('/usr/local/bin/composer') }
  action :run
end


# NGINX install
include_recipe 'nginx::server'

node['nginx']['sites'].each do |site|
  git site['git_path'] do
    repository site['git_repo']
    revision site['git_branch']
    action :sync
    user 'deploy'
    group 'deploy'
    ssh_wrapper "ssh -i #{home_basedir}/deploy/.ssh/git_rsa"
    notifies :restart, 'service[php-fpm]'
    only_if { site['git'] && ::File.exist?("#{home_basedir}/deploy/.ssh/git_rsa") } # rubocop:disable LineLength
  end

  nginx_site site['name'] do
    listen '*:80'
    host site['host']
    root site['root']
    index site['index']
    slashlocation site['slashlocation']
    phpfpm site['phpfpm']
    templatesource site['templatesource']
    templatecookbook site['templatecookbook']
    action [:create, :enable]
    notifies :restart, 'service[php-fpm]'
  end

  execute "Migrating #{site['name']} with artisan" do
    command "php #{site['root']}/../artisan migrate"
    action :run
    only_if { site['artisan_migrate'] }
  end
end
