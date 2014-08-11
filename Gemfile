source "https://rubygems.org"

chef_version = ENV.fetch("CHEF_VERSION", "11.10")

gem "chef", "~> #{chef_version}"

gem "berkshelf", "~> 3.1.0"
gem "foodcritic", "~> 3.0.0"
gem "rubocop", "~> 0.22.0"

group :integration do
  gem "kitchen-vagrant", "~> 0.15.0"
  gem "test-kitchen", "~> 1.2.1"
end
