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

include_recipe 'appserver::userconfig'
include_recipe 'appserver::dbserver'
include_recipe 'appserver::webserver'

if node['swapsize'] > 0
  swap_file '/mnt/swap' do
    size node['swapsize']
  end
end
