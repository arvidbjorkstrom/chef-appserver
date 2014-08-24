#
# Cookbook Name:: chef-appserver
# Recipe:: default
#

include_recipe 'timezone-ii'
include_recipe 'apt'
include_recipe 'zsh'
include_recipe 'git'
include_recipe 'chef-solo-search'
include_recipe 'users::sysadmins'
include_recipe 'oh-my-zsh'

# Add custom agnoster2 oh-my-zsh theme
search(:users, 'shell:*zsh NOT action:remove').each do |u|
  template "/home/#{u['id']}/.oh-my-zsh/themes/agnoster2.zsh-theme" do
    source 'agnoster2.zsh-theme.erb'
    owner u['id']
    group u['id']
    mode '0644'
    only_if { ::File.directory?("/home/#{u['id']}/.oh-my-zsh/themes") }
  end
end

# Create private keys for git use
search(:users, 'git_key:* NOT git_key:Add* NOT action:remove').each do |u|
  template "Add git key to user #{u['id']}" do
    path "/home/#{u['id']}/.ssh/git_rsa"
    source 'ssh_key.erb'
    owner u['id']
    group u['id']
    mode '0400'
    variables ssh_key: u['git_key']
    only_if { ::File.directory?("/home/#{u['id']}/.ssh") }
    not_if { ::File.exist?("/home/#{u['id']}/.ssh/git_rsa") }
  end
end

include_recipe 'appserver::dbserver'
include_recipe 'appserver::webserver'
