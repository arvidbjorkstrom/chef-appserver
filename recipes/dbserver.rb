#
# Cookbook Name:: appserver
# Recipe:: dbserver
#

include_recipe 'mysql::client'
include_recipe 'mysql::server'

include_recipe 'database::mysql'

mysql_connection = {
  host:     'localhost',
  username: node['mysql']['server_root_username'],
  password: node['mysql']['server_root_password']
}

node['mysql']['databases'].each do |db|

  if db['overwrite']
    mysql_database db['database'] do
      connection mysql_connection
      action [:drop, :create]
    end

    mysql_database_user db['username'] do
      connection mysql_connection
      host 'localhost'
      password db['password']
      database_name db['database']
      action [:create, :grant]
    end

    execute "Import to #{db['database']}" do
      command "mysql -u #{node['mysql']['server_root_username']} -p\"#{node['mysql']['server_root_password']}\" #{db['database']} < /tmp/#{db['database']}.sql" # rubocop:disable LineLength
      action :run
      only_if { ::File.exist?("/tmp/#{db['database']}.sql") }
    end
  else
    mysql_database db['database'] do
      connection mysql_connection
      action :create
    end

    mysql_database_user db['username'] do
      connection mysql_connection
      host 'localhost'
      password db['password']
      database_name db['database']
      action [:create, :grant]
    end
  end
end
