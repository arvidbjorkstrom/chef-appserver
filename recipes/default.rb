#
# Cookbook Name:: chef-appserver
# Recipe:: default
#

# Set home_basedir based on platform_family
case node['platform_family']
when 'mac_os_x'
  home_basedir = '/Users'
when 'debian', 'rhel', 'fedora', 'arch', 'suse', 'freebsd'
  home_basedir = '/home'
end

include_recipe 'timezone-ii'
include_recipe 'apt'
include_recipe 'zsh'
include_recipe 'git'
include_recipe "chef-solo-search"
include_recipe "users::sysadmins"
include_recipe "oh-my-zsh"
search( :users, 'shell:*zsh AND NOT action:remove' ).each do |u|
  user_id = u["id"]

  template "#{home_basedir}/#{user_id}/.oh-my-zsh/themes/agnoster2.zsh-theme" do
    source 'agnoster2.zsh-theme.erb'
    owner 'deploy'
    group 'deploy'
    mode '0644'
    only_if { ::File.directory?("#{home_basedir}/#{user_id}/.oh-my-zsh/themes") } # rubocop:disable LineLength
  end
end
include_recipe 'appserver::dbserver'
include_recipe 'appserver::webserver'
