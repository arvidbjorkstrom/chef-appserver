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
%w(php5 php5-cli php5-mysql php5-curl php5-mcrypt php5-gd imagemagick php5-imagick).each do |pkg|
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
  command 'curl -sS https://getcomposer.org/installer | php;mv composer.phar /usr/local/bin/composer'
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
  composer_path = "#{site['base_path']}/#{site['composer_subpath']}" if site['composer_install']
  artisan_path = "#{site['base_path']}/#{site['artisan_subpath']}" if site['artisan_migrate']
  compass_path = "#{site['base_path']}/#{site['compass_subpath']}" if site['compass_compile']
  webroot_path = "#{site['base_path']}/#{site['webroot_subpath']}"

  if site['ssl']
    directory "#{node['nginx']['dir']}/ssl" do
      owner 'root'
      group 'root'
      mode '0775'
      action :create
      not_if { ::File.directory?("#{node['nginx']['dir']}/ssl") }
    end

    file "#{node['nginx']['dir']}/ssl/#{site['name']}.crt" do
      content site['ssl_crt']
      owner 'root'
      group 'root'
      mode '0400'
      not_if { ::File.exist?("#{node['nginx']['dir']}/ssl/#{site['name']}/.crt") }
    end
    file "#{node['nginx']['dir']}/ssl/#{site['name']}.key" do
      content site['ssl_key']
      owner 'root'
      group 'root'
      mode '0400'
      not_if { ::File.exist?("#{node['nginx']['dir']}/ssl/#{site['name']}/.crt") }
    end
    custom_data = {
      'environment' => site['environment'],
      'db_host' => site['db_host'],
      'db_database' => site['db_database'],
      'db_username' => site['db_username'],
      'db_password' => site['db_password'],
      'ssl' => true,
      'ssl_crt' => "#{node['nginx']['dir']}/ssl/#{site['name']}.crt",
      'ssl_key' => "#{node['nginx']['dir']}/ssl/#{site['name']}.key"
    }
  else
    custom_data = {
      'environment' => site['environment'],
      'db_host' => site['db_host'],
      'db_database' => site['db_database'],
      'db_username' => site['db_username'],
      'db_password' => site['db_password'],
      'ssl' => false
    }
  end

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
    notifies :sync, "git[Syncing git repository for #{site['name']}]"
    notifies :run, "execute[Composer install #{site['name']}]"
    notifies :run, "execute[Artisan migrate #{site['name']}]"
  end

  # Sync with git repository
  git "Syncing git repository for #{site['name']}" do
    destination git_path
    repository site['git_repo']
    revision site['git_branch']
    action :nothing
    user deploy_usr
    ssh_wrapper "/home/#{deploy_usr}/git_wrapper.sh"
    only_if { site['git'] && ::File.exist?("/home/#{deploy_usr}/.ssh/git_rsa") }
    notifies :run, "execute[Composer install #{site['name']} after git sync]"
    notifies :run, "ruby_block[Set writeable dirs for #{site['name']} after git sync]"
    notifies :compile, "compass_project[Compile sass for #{site['name']} after git sync]", :immediately
  end


  # Composer install triggered by git sync
  execute "Composer install #{site['name']} after git sync" do
    command "composer install -n -d #{composer_path}"
    action :nothing
    user deploy_usr
    only_if { site['git'] && site['composer_install'] }
    notifies :run, "execute[Artisan migrate #{site['name']} after composer]"
  end

  # Composer install without git
  execute "Composer install #{site['name']}" do
    command "composer install -n -d #{composer_path}"
    action :nothing
    user deploy_usr
    only_if { site['composer_install'] }
    not_if { site['git'] }
    notifies :run, "execute[Artisan migrate #{site['name']} after composer]"
  end


  # Artisan migrate triggered by composer install
  execute "Artisan migrate #{site['name']} after composer" do
    command "php #{artisan_path} --env=#{site['environment']} migrate"
    action :nothing
    user deploy_usr
    only_if { site['composer_install'] && site['artisan_migrate'] }
  end

  # Artisan migrate without composer install
  execute "Artisan migrate #{site['name']}" do
    command "php #{artisan_path} --env=#{site['environment']} migrate"
    action :nothing
    user deploy_usr
    only_if { site['artisan_migrate'] }
    not_if { site['composer_install'] }
  end

  # Compass compile without git
  compass_project "Compile sass for #{site['name']}" do
    path compass_path
    action :compile
    user deploy_usr
    only_if { site['compass_compile'] }
    not_if { site['git'] }
  end

  # Compass compile triggered by git
  compass_project "Compile sass for #{site['name']} after git sync" do
    path compass_path
    action :nothing
    user deploy_usr
    only_if { site['compass_compile'] }
  end

  # Set writeable directories without git
  if site['writeable_dirs'].is_a?(Array) && !site['git']
    site['writeable_dirs'].each do |dir_path|
      dir_path = "#{site['base_path']}/#{dir_path}" unless dir_path[0, 1] == '/'
      execute "Set owner of #{dir_path} to #{deploy_usr}:www-data" do
        command "chown -R #{deploy_usr}:www-data #{dir_path}"
        action :run
        only_if { ::File.directory?(dir_path) }
      end
      execute "Change mode of #{dir_path} to 775" do
        command "chmod -R 775 #{dir_path}"
        only_if { ::File.directory?(dir_path) }
      end
    end
  end

  # Set writeable directories after git sync
  ruby_block "Set writeable dirs for #{site['name']} after git sync" do
    block do
      site['writeable_dirs'].each do |dir_path|
        dir_path = "#{site['base_path']}/#{dir_path}" unless dir_path[0, 1] == '/'

        r = Chef::Resource::Execute.new("Set owner of #{dir_path} to #{deploy_usr}:www-data", run_context)
        r.command "chown -R #{deploy_usr}:www-data #{dir_path}"
        r.run_action(:run)

        r = Chef::Resource::Execute.new("Change mode of #{dir_path} to 775", run_context)
        r.command "chmod -R 775 #{dir_path}"
        r.run_action(:run)
      end
    end
    action :nothing
    only_if { site['writeable_dirs'].is_a?(Array) }
  end
end
