#
# Cookbook Name:: appserver
# Recipe:: webserver
#

# Set deploy_usr
deploy_usr = 'vagrant'
def chef_solo_search_installed?
  klass = ::Search.const_get('Helper')
  return klass.is_a?(Class)
rescue NameError
  return false
end
unless Chef::Config[:solo] && !chef_solo_search_installed?
  search(:users, 'id:deploy NOT action:remove').each do |u|
    deploy_usr = u['id']
  end
end

# Compass
include_recipe 'compass'

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
  owner deploy_usr
  group 'sysadmin'
  mode '0775'
  action :create
  not_if { ::File.directory?('/var/www') }
end

node['nginx']['sites'].each do |site|

  git_path = "#{site['base_path']}/#{site['git_subpath']}" if site['git']
  composer_path = "#{site['base_path']}/#{site['composer_subpath']}"
  artisan_path = "#{site['base_path']}/#{site['artisan_subpath']}"
  compass_path = "#{site['base_path']}/#{site['compass_subpath']}"
  webroot_path = "#{site['base_path']}/#{site['webroot_subpath']}"

  git "Syncing git repository for #{site['name']}" do
    destination git_path
    repository site['git_repo']
    revision site['git_branch']
    checkout_branch site['git_branch']
    action :sync
    user deploy_usr
    ssh_wrapper "/home/#{deploy_usr}/git_wrapper.sh"
    only_if { site['git'] && ::File.exist?("/home/#{deploy_usr}/.ssh/git_rsa") }
    notifies :run, "execute[Composer update #{site['name']} after git sync]"
  end


  # Composer update triggered by git sync
  execute "Composer update #{site['name']} after git sync" do
    command "composer update -n -d #{composer_path}"
    action :nothing
    user deploy_usr
    only_if { site['git'] && site['composer_update'] }
    notifies :run, "execute[Artisan migrate #{site['name']} after composer]"
  end

  # Composer update without git
  execute "Composer update #{site['name']}" do
    command "composer update -n -d #{composer_path}"
    action :run
    user deploy_usr
    only_if { site['composer_update'] }
    not_if { site['git'] }
    notifies :run, "execute[Artisan migrate #{site['name']} after composer]"
  end


  # Artisan migrate triggered by composer update
  execute "Artisan migrate #{site['name']} after composer" do
    command "php #{artisan_path} --env=#{site['environment']} migrate"
    action :nothing
    user deploy_usr
    only_if { site['composer_update'] && site['artisan_migrate'] }
  end

  # Artisan migrate without composer update
  execute "Artisan migrate #{site['name']}" do
    command "php #{artisan_path} --env=#{site['environment']} migrate"
    action :run
    user deploy_usr
    only_if { site['artisan_migrate'] }
    not_if { site['composer_update'] }
  end

  # Compass compile
  compass_project site['name'] do
    path compass_path
    action :compile
    user deploy_usr
    only_if { site['compass_compile'] }
  end

  # Set writeable directories
  if site['writeable_dirs'].kind_of?(Array)
    site['writeable_dirs'].each do |dir_path|
      dir_path = "#{site['base_path']}/#{dir_path}" unless dir_path[0, 1] == '/'
      execute "Make #{dir_path} owned by #{deploy_usr}:www-data" do
        command "chown -R #{deploy_usr}:www-data #{dir_path}"
        action :run
        only_if { ::File.directory?(dir_path) }
      end
      execute "Make #{dir_path} writeable by both #{deploy_usr} and www-data" do
        command "chmod -R 775 #{dir_path}"
        only_if { ::File.directory?(dir_path) }
      end
    end
  end

  custom_data = { 'environment' => site['environment'] }

  # Set up nginx server block
  nginx_site site['name'] do
    listen '*:80'
    host site['host']
    root webroot_path
    index site['index']
    location site['location']
    phpfpm site['phpfpm']
    custom_data custom_data
    template_cookbook site['template_cookbook']
    template_source site['template_source']
    action [:create, :enable]
    notifies :restart, 'service[php-fpm]'
    notifies :restart, 'service[nginx]'
  end
end
