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
include_recipe 'compass' if node['compass']['install']

# Node JS & packages
include_recipe 'nodejs'
node['nodejs']['npm']['packages'].each do |npackage|
  nodejs_npm npackage
end

# NGINX install
include_recipe 'nginx::server'

# sudo add-apt-repository ppa:ondrej/php; sudo apt-get update
apt_repository 'ondrej-php' do
  uri 'ppa:ondrej/php'
end

# PHP
package "php#{node['php']['version']}"

package 'imagemagick'

# PHP plugins
%w[-cli -mysql -curl -mcrypt -gd -imagick -fpm].each do |pkg|
  package "php#{node['php']['version']}#{pkg}"
end

# PHP FPM service
service_provider = nil
if  'ubuntu' == node['platform']
  if Chef::VersionConstraint.new('>= 15.04').include?(node['platform_version'])
    service_provider = Chef::Provider::Service::Systemd
  elsif Chef::VersionConstraint.new('>= 12.04').include?(node['platform_version'])
    service_provider = Chef::Provider::Service::Upstart
  end
end
service 'php-fpm' do
  provider service_provider
  service_name "php#{node['php']['version']}-fpm"
  supports enable: true, start: true, stop: true, restart: true
  # :reload doesnt work on ubuntu 14.04 because of a bug...
  action [:enable, :start]
end

template "/etc/php/#{node['php']['version']}/fpm/php.ini" do
  source 'php.ini.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[php-fpm]'
end

template "/etc/php/#{node['php']['version']}/mods-available/opcache.ini" do
  source 'opcache.ini.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[php-fpm]'
end

execute 'Enable Mcrypt' do
  command 'phpenmod mcrypt'
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

# Install supervisor
include_recipe 'supervisor'

directory '/var/www' do
  owner deploy_usr
  group 'sysadmin'
  mode '0775'
  action :create
end

node['nginx']['sites'].each do |site|
  webroot_path = "#{site['base_path']}/#{site['webroot_subpath']}"
  git_path = "#{site['base_path']}/#{site['git_subpath']}" if site['git']
  composer_path = "#{site['base_path']}/#{site['composer_subpath']}" if site['composer_install']
  artisan_path = "#{site['base_path']}/#{site['artisan_subpath']}"
  compass_path = "#{site['base_path']}/#{site['compass_subpath']}" if site['compass_compile']
  npm_path = "#{site['base_path']}/#{site['npm_subpath']}" if site['npm_install']
  bower_path = "#{site['base_path']}/#{site['bower_subpath']}" if site['bower_install']
  gulp_path = "#{site['base_path']}/#{site['gulp_subpath']}" if site['gulp_run']
  workerlog_path = "#{site['base_path']}/#{site['artisan_queuelogpath']}" if site['artisan_queuelisten']

  # Create ssl cert files
  if site['ssl']
    directory "#{node['nginx']['dir']}/ssl" do
      owner 'root'
      group 'root'
      mode '0775'
      action :create
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
  end

  # Set up nginx server block
  custom_data = {
    'environment' => site['environment'],
    'db_host' => site['db_host'],
    'db_database' => site['db_database'],
    'db_username' => site['db_username'],
    'db_password' => site['db_password'],
    'ssl' => site['ssl'],
    'ssl_crt' => "#{node['nginx']['dir']}/ssl/#{site['name']}.crt",
    'ssl_key' => "#{node['nginx']['dir']}/ssl/#{site['name']}.key",
    'redirect-hosts' => site['redirect-hosts'],
    'redirect-to' => site['redirect-to']
  }
  nginx_site site['name'] do # ~FC022
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
    not_if { ::File.exist?("#{node['nginx']['dir']}/sites-enabled/#{site['name']}") }
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
    action :sync
    user deploy_usr
    ssh_wrapper "/home/#{deploy_usr}/git_wrapper.sh"
    only_if { site['git'] && ::File.exist?("/home/#{deploy_usr}/.ssh/git_rsa") }
    only_if { ::File.exist?("#{node['nginx']['dir']}/sites-enabled/#{site['name']}") }
    notifies :run, "execute[Composer install #{site['name']} after git sync]"
    notifies :run, "execute[Artisan migrate #{site['name']} after git sync]"
    notifies :compile, "compass_project[Compile sass for #{site['name']} after git sync]", :immediately
    notifies :run, "execute[Npm install #{site['name']} after git sync]"
    notifies :run, "ruby_block[Set writeable dirs for #{site['name']} after git sync]"
    notifies :create, "template[Create #{site['base_path']}/.env after git sync]"
  end

  # Create .env file efter git sync
  template "Create #{site['base_path']}/.env after git sync" do
    path "#{site['base_path']}/.env"
    source 'env.erb'
    owner deploy_usr
    group 'www-data'
    mode '0755'
    action :nothing
    only_if { site['env'] }
  end

  # Create .env file without git sync
  template "Create #{site['base_path']}/.env" do
    path "#{site['base_path']}/.env"
    source 'env.erb'
    owner deploy_usr
    group 'www-data'
    mode '0755'
    not_if { site['git'] }
    only_if { site['env'] }
  end

  # Composer install triggered by git sync
  execute "Composer install #{site['name']} after git sync" do
    command "composer install -n -q -d #{composer_path}"
    action :nothing
    user deploy_usr
    only_if { site['composer_install'] }
    only_if { ::File.directory?(composer_path) }
    notifies :run, "execute[Artisan migrate #{site['name']} after composer]"
  end

  # Composer install without git
  execute "Composer install #{site['name']}" do
    command "composer install -n -q -d #{composer_path}"
    action :run
    user deploy_usr
    only_if { site['composer_install'] }
    only_if { ::File.directory?(composer_path) }
    only_if { ::File.exist?("#{node['nginx']['dir']}/sites-enabled/#{site['name']}") }
    not_if { site['git'] }
    notifies :run, "execute[Artisan migrate #{site['name']} after composer]"
  end

  # Artisan migrate triggered by composer install
  execute "Artisan migrate #{site['name']} after composer" do
    command "php #{artisan_path} --env=#{site['environment']} migrate"
    action :nothing
    user deploy_usr
    only_if { site['artisan_migrate'] }
    only_if { ::File.directory?(artisan_path) }
  end

  # Artisan migrate after git, when not running composer install
  execute "Artisan migrate #{site['name']} after git sync" do
    command "php #{artisan_path} --env=#{site['environment']} migrate"
    action :nothing
    user deploy_usr
    only_if { site['artisan_migrate'] }
    only_if { ::File.directory?(artisan_path) }
    not_if { site['composer_install'] }
  end

  # Artisan migrate without either composer or git
  execute "Artisan migrate #{site['name']}" do
    command "php #{artisan_path} --env=#{site['environment']} migrate"
    action :run
    user deploy_usr
    only_if { site['artisan_migrate'] }
    only_if { ::File.directory?(artisan_path) }
    only_if { ::File.exist?("#{node['nginx']['dir']}/sites-enabled/#{site['name']}") }
    not_if { site['composer_install'] }
    not_if { site['git'] }
  end

  # Compass compile without git
  compass_project "Compile sass for #{site['name']}" do
    path compass_path
    action :compile
    user deploy_usr
    only_if { site['compass_compile'] }
    only_if { ::File.directory?(compass_path) }
    not_if { site['git'] }
  end

  # Compass compile triggered by git
  compass_project "Compile sass for #{site['name']} after git sync" do
    path compass_path
    action :nothing
    user deploy_usr
    only_if { site['compass_compile'] }
    only_if { ::File.directory?(compass_path) }
  end

  # Npm install without git
  execute "Npm install #{site['name']}" do
    cwd npm_path
    command 'npm install'
    action :run
    user deploy_usr
    only_if { site['npm_install'] }
    only_if { ::File.directory?(npm_path) }
    not_if { site['git'] }
    notifies :run, "execute[Bower install #{site['name']}]"
    notifies :run, "execute[Gulp #{site['name']}]"
  end

  # Npm install triggered by git
  execute "Npm install #{site['name']} after git sync" do
    cwd npm_path
    command 'npm install --silent'
    action :nothing
    user deploy_usr
    only_if { site['npm_install'] }
    only_if { ::File.directory?(npm_path) }
    notifies :run, "execute[Bower install #{site['name']}]"
    notifies :run, "execute[Gulp #{site['name']}]"
  end

  # Bower install after npm install
  execute "Bower install #{site['name']}" do
    cwd bower_path
    command "su #{deploy_usr} -l -c 'bower install --silent'"
    action :nothing
    only_if { site['bower_install'] }
    only_if { ::File.directory?(bower_path) }
    notifies :run, "execute[Gulp #{site['name']}]"
  end

  # Gulp run after bower install
  execute "Gulp #{site['name']} after bower" do
    cwd gulp_path
    command 'gulp --silent --production'
    action :nothing
    user deploy_usr
    only_if { site['gulp_run'] }
    only_if { ::File.directory?(gulp_path) }
  end

  # Gulp run after npm install
  execute "Gulp #{site['name']}" do
    cwd gulp_path
    command 'gulp --silent --production'
    action :nothing
    user deploy_usr
    only_if { site['gulp_run'] }
    only_if { ::File.directory?(gulp_path) }
    not_if { site['bower_install'] }
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

  # Set up supervisors
  supervisor_service "#{site['name']}ArtisanQueue" do
    command "php #{artisan_path} --env=#{site['environment']} queue:work --tries=3 --daemon"
    autostart true
    autorestart true
    user deploy_usr
    numprocs site['artisan_queueworkers']
    process_name '%(program_name)s_%(process_num)02d'
    redirect_stderr true
    stdout_logfile workerlog_path
    only_if { site['artisan_queuelisten'] }
  end

  # Set up artisan cron entries
  site['artisan_cron'].each do |cronjob|
    cronjob['minute'] ||= '*'
    cronjob['hour'] ||= '*'
    cronjob['month'] ||= '*'
    cronjob['weekday'] ||= '*'

    cron cronjob['name'] do
      minute cronjob['minute']
      hour cronjob['hour']
      month cronjob['month']
      weekday cronjob['weekday']
      command "php #{artisan_path} --env=#{site['environment']} #{cronjob['command']}"
      user deploy_usr
    end
  end

  # Set up cron entries
  site['cronjobs'].each do |cronjob|
    cronjob['minute'] ||= '*'
    cronjob['hour'] ||= '*'
    cronjob['month'] ||= '*'
    cronjob['weekday'] ||= '*'

    cron cronjob['name'] do
      minute cronjob['minute']
      hour cronjob['hour']
      month cronjob['month']
      weekday cronjob['weekday']
      command cronjob['command']
      user deploy_usr
    end
  end
end
