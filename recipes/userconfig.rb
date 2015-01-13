def chef_solo_search_installed?
  klass = ::Search.const_get('Helper')
  return klass.is_a?(Class)
rescue NameError
  return false
end

if Chef::Config[:solo] && !chef_solo_search_installed?
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search unless you install the chef-solo-search cookbook.') # rubocop:disable LineLength
else
  # Add custom agnoster2 oh-my-zsh theme
  search(:users, 'shell:*zsh NOT action:remove').each do |u|
    directory "/home/#{u['id']}/.oh-my-zsh/custom/themes" do
      owner u['id']
      group u['id']
      mode '0775'
      action :create
      not_if { ::File.directory?("/home/#{u['id']}/.oh-my-zsh/custom/themes") }
    end
    template "/home/#{u['id']}/.oh-my-zsh/custom/themes/agnoster2.zsh-theme" do
      source 'agnoster2.zsh-theme.erb'
      owner u['id']
      group u['id']
      mode '0644'
      only_if { ::File.directory?("/home/#{u['id']}/.oh-my-zsh/custom/themes") }
    end
  end

  # Create private keys for git use
  search(:users, 'git_key:* NOT git_key:Add* NOT action:remove').each do |u|
    file "/home/#{u['id']}/.ssh/git_rsa" do
      content u['git_key']
      owner u['id']
      group u['id']
      mode '0400'
      only_if { ::File.directory?("/home/#{u['id']}/.ssh") }
      not_if { ::File.exist?("/home/#{u['id']}/.ssh/git_rsa") }
    end

    template "Add git wrapper for user #{u['id']}" do
      path "/home/#{u['id']}/git_wrapper.sh"
      source 'git_wrapper.sh.erb'
      owner u['id']
      group u['id']
      mode '0540'
      only_if { ::File.exist?("/home/#{u['id']}/.ssh/git_rsa") }
    end
  end

  # Make git ignore file permissions
  search(:users, 'NOT action:remove').each do |u|
    execute "Make git ignore file permissions for user #{u['id']}" do
      command "su #{u['id']} -l -c 'git config --global core.filemode false'"
      action :run
    end
  end
end
