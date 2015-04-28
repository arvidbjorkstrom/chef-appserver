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

package 'unzip'

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

    execute "Unzip #{db['database']}.sql.zip" do
      command "unzip /vagrant/#{db['database']}.sql.zip -d /tmp/"
      creates "/tmp/#{db['database']}.sql"
      action :run
      not_if { ::File.exist?("/vagrant/#{db['database']}.sql") }
      notifies :run, "execute[Import to #{db['database']}]", :immediately
    end
    execute "Copy #{db['database']}.sql" do
      command "cp /vagrant/#{db['database']}.sql /tmp/#{db['database']}.sql"
      creates "/tmp/#{db['database']}.sql"
      action :run
      only_if { ::File.exist?("/vagrant/#{db['database']}.sql") }
      notifies :run, "execute[Import to #{db['database']}]", :immediately
    end
    execute "Import to #{db['database']}" do
      command "mysql -u #{node['mysql']['server_root_username']} -p\"#{node['mysql']['server_root_password']}\" #{db['database']} < /tmp/#{db['database']}.sql" # rubocop:disable LineLength
      action :nothing
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
