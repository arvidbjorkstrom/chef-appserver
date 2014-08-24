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

    template "Add git wrapper for user #{u['id']}" do
      path "/home/#{u['id']}/git_wrapper.sh"
      source 'git_wrapper.sh.erb'
      owner u['id']
      group u['id']
      mode '0540'
      only_if { ::File.exist?("/home/#{u['id']}/.ssh/git_rsa") }
    end
  end
end
