#
# Cookbook Name:: chef-appserver
# Recipe:: default
#

include_recipe 'timezone-ii'
include_recipe 'apt'
include_recipe 'git'
include_recipe 'deployer'
include_recipe 'appserver::dbserver'
include_recipe 'appserver::webserver'
