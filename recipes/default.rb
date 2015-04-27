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
  swap_file "Create #{swapfilesize}MB swap file at /mnt/swap" do
    path '/mnt/swap'
    size node['swapsize']
  end
end

include_recipe 'appserver::userconfig'
include_recipe 'appserver::dbserver'
include_recipe 'appserver::webserver'
