#
# Cookbook Name:: appserver
# Recipe:: dbserver
#

include_recipe 'mysql::client'
include_recipe 'mysql::server'

mysql_command = "mysql -h'localhost' -u'#{node['mysql']['server_root_username']}' -p'#{node['mysql']['server_root_password']}'" # rubocop:disable LineLength

package 'unzip'

node['mysql']['databases'].each do |db|
  if db['overwrite']
    execute "Create user #{db['username']}" do
      command "#{mysql_command} -e \"CREATE USER IF NOT EXISTS '#{db['username']}'@'localhost'\""
      action :run
      notifies :run, "Set password for user #{db['username']}"
    end

    execute "Set password for user #{db['username']}" do
      command "#{mysql_command} -e \"SET PASSWORD FOR '#{db['username']}'@'localhost' = '#{db['password']}'\"" 
      action :nothing
      notifies :run, "Create database #{db['database']}"
    end

    execute "Create database #{db['database']}" do
      command "#{mysql_command} -e \"CREATE DATABASE IF NOT EXISTS '#{db['database']}'\""
      action :nothing
      notifies :run, "Grant #{db['username']} access to #{db['database']}"
    end

    execute "Grant #{db['username']} access to #{db['database']}" do
      command "#{mysql_command} -e \"GRANT ALL PRIVILEGES ON '#{db['database']}' . * TO '#{db['username']}'@'localhost'\"" # rubocop:disable LineLength
      action :nothing
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
      command "#{mysql_command} #{db['database']} < /tmp/#{db['database']}.sql"
      action :nothing
      only_if { ::File.exist?("/tmp/#{db['database']}.sql") }
    end
  else

    execute "Create user #{db['username']}" do
      command "#{mysql_command} -e \"CREATE USER IF NOT EXISTS '#{db['username']}'@'localhost'\""
      action :run
      notifies :run, "Set password for user #{db['username']}"
    end

    execute "Set password for user #{db['username']}" do
      command "#{mysql_command} -e \"SET PASSWORD FOR '#{db['username']}'@'localhost' = '#{db['password']}'\""
      action :nothing
      notifies :run, "Create database #{db['database']}"
    end

    execute "Create database #{db['database']}" do
      command "#{mysql_command} -e \"CREATE DATABASE IF NOT EXISTS '#{db['database']}'\""
      action :nothing
      notifies :run, "Grant #{db['username']} access to #{db['database']}"
    end

    execute "Grant #{db['username']} access to #{db['database']}" do
      command "#{mysql_command} -e \"GRANT ALL PRIVILEGES ON '#{db['database']}' . * TO '#{db['username']}'@'localhost'\"" # rubocop:disable LineLength
      action :nothing
    end
  end
end

# Auto MySQL Backup
package 'automysqlbackup'

# Redis
if node['redisio']['install']
  include_recipe 'redisio'
  include_recipe 'redisio::enable'
end
