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

# Upgrade or install composer
execute 'Upgrade Composer' do
  command 'composer self-update'
  only_if { ::File.exist?('/usr/local/bin/composer') }
  action :run
end
execute 'Install Composer' do # ~FC041
  command 'curl -sS https://getcomposer.org/installer | php;mv composer.phar /usr/local/bin/composer' # rubocop:disable LineLength
  not_if { ::File.exist?('/usr/local/bin/composer') }
  action :run
end


# NGINX install
include_recipe 'nginx::server'

directory '/var/www' do
  owner 'deploy'
  group 'sysadmin'
  mode '0775'
  action :create
  not_if { ::File.directory?('/var/www') }
end

node['nginx']['sites'].each do |site|
  git "Syncing git repository for #{site['name']}" do
    destination site['git_path']
    repository site['git_repo']
    revision site['git_branch']
    action :sync
    user 'deploy'
    group 'deploy'
    ssh_wrapper '/home/deploy/git_wrapper.sh'
    only_if { site['git'] && ::File.exist?('/home/deploy/.ssh/git_rsa') }
    notifies :run, "execute[Composer update #{site['name']} after git sync]"
  end


  # Composer update triggered by git sync
  execute "Composer update #{site['name']} after git sync" do
    command "composer update -n -d #{site['composer_update_path']}"
    action :nothing
    only_if { site['git'] && site['composer_update'] }
    notifies :run, "execute[Artisan migrate #{site['name']} after composer]"
  end

  # Composer update without git
  execute "Composer update #{site['name']}" do
    command "composer update -n -d #{site['composer_update_path']}"
    action :run
    only_if { site['composer_update'] }
    not_if { site['git'] }
    notifies :run, "execute[Artisan migrate #{site['name']} after composer]"
  end


  # Artisan migrate triggered by composer update
  execute "Artisan migrate #{site['name']} after composer" do
    command "php #{site['root']}/../artisan migrate"
    action :nothing
    only_if { site['composer_update'] && site['artisan_migrate'] }
  end

  # Artisan migrate without composer update
  execute "Artisan migrate #{site['name']}" do
    command "php #{site['root']}/../artisan migrate"
    action :run
    only_if { site['artisan_migrate'] }
    not_if { site['composer_update'] }
  end

  # Set writeable directories
  if site['writeable_dirs'].kind_of?(Array)
    site['writeable_dirs'].each do |dir_path|
      dir_path = "#{site['git_path']}/#{dir_path}" unless dir_path[0, 1] == '/'
      execute "Make #{dir_path} owned by www-data:deploy" do
        command "chown -R www-data:deploy #{dir_path}"
        action :run
        only_if { ::File.directory?(dir_path) }
      end
      execute "Make #{dir_path} writeable by both www-data and deploy" do
        command "chmod -R 775 #{dir_path}"
        only_if { ::File.directory?(dir_path) }
      end
    end
  end

  # Set up nginx server block
  nginx_site site['name'] do
    listen '*:80'
    host site['host']
    root site['root']
    index site['index']
    location site['location']
    phpfpm site['phpfpm']
    template_cookbook site['template_cookbook']
    template_source site['template_source']
    action [:create, :enable]
    notifies :restart, 'service[php-fpm]'
    notifies :restart, 'service[nginx]'
  end
end
