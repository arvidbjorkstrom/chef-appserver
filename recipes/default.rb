#
# Cookbook Name:: appserver
# Recipe:: default
#

include_recipe 'timezone-ii'
include_recipe 'apt'
include_recipe 'zsh'
include_recipe 'git'
include_recipe 'chef-solo-search'
include_recipe 'users::sysadmins'
include_recipe 'sudo'
include_recipe 'oh-my-zsh'

if node['swapsize'] > 0
  servermemory = `memsize=$(free -b | grep "Mem:" | awk '{print $2}');echo "$(($memsize/1024/1024))";`
  swapfilesize = servermemory.to_i * node['swapsize'].to_i
  swap_file "Create #{swapfilesize}MB swap file at /mnt/swap" do
    path '/mnt/swap'
    size swapfilesize
    persist true
  end
end

include_recipe 'appserver::userconfig'
include_recipe 'appserver::dbserver'
include_recipe 'appserver::webserver'
