#
# Cookbook Name:: appserver
# Recipe:: default
#

apt_repository 'brightbox-ruby-ng' do
  uri 'ppa:brightbox/ruby-ng'
end
package 'ruby2.3'
package 'ruby2.3-dev'
package 'make'

include_recipe 'timezone-ii'
include_recipe 'apt'
include_recipe 'zsh'
include_recipe 'git'
include_recipe 'chef-solo-search'
include_recipe 'users::sysadmins'
include_recipe 'sudo'
include_recipe 'oh-my-zsh'

if node['swapsize'] > 0
  servermemory = Mixlib::ShellOut.new(
    "memsize=$(free -b | grep 'Mem:' | awk '{print $2}');echo \"$(($memsize/1024/1024))\";"
  )
  servermemory.run_command
  swapfilesize = servermemory.stdout.to_i * node['swapsize'].to_i
  swap_file "Create #{swapfilesize}MB swap file at /mnt/swap" do
    path '/mnt/swap'
    size swapfilesize
    persist true
  end
end

include_recipe 'appserver::userconfig'
include_recipe 'appserver::dbserver'
include_recipe 'appserver::webserver'
