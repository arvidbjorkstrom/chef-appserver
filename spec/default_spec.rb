require 'spec_helper'

describe 'appserver::default' do
  it { expect(chef_run).to include_recipe('timezone-ii') }
  it { expect(chef_run).to include_recipe('apt') }
  it { expect(chef_run).to include_recipe('zsh') }
  it { expect(chef_run).to include_recipe('git') }
  it { expect(chef_run).to include_recipe('chef-solo-search') }
  it { expect(chef_run).to include_recipe('users::sysadmins') }
  it { expect(chef_run).to include_recipe('sudo') }
  it { expect(chef_run).to include_recipe('oh-my-zsh') }

  it { expect(chef_run).to include_recipe('appserver::userconfig') }
  it { expect(chef_run).to include_recipe('appserver::dbserver') }
  it { expect(chef_run).to include_recipe('appserver::webserver') }
end
