#
# Cookbook Name:: chef-appserver
# Recipe:: default
#

include_recipe 'timezone-ii'
include_recipe 'apt'
include_recipe "chef-solo-search"
include_recipe "lxmx_oh_my_zsh"
include_recipe "users::sysadmins"
include_recipe 'git'
include_recipe 'appserver::dbserver'
include_recipe 'appserver::webserver'
