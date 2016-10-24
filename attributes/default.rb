#
# Cookbook Name:: appserver
# Attributes:: default
#

# Swap file, multiples of the server memory size
default['swapsize'] = 0

# Timezone
default['tz'] = 'Europe/Stockholm'

# Sudo
default['authorization']['sudo']['groups'] = %w(admin wheel sysadmin)
default['authorization']['sudo']['passwordless'] = true

# MySQL
default['mysql']['server_root_username'] = 'root'
default['mysql']['server_root_password'] = 'YouShouldReplaceThis'
default['mysql']['server_debian_password'] = 'YouShouldReplaceThis'
default['mysql']['databases'] = []

default['automysqlbackup']['mysql_dump_password'] = node['mysql']['server_root_password']

# NGINX
default['nginx']['sites'] = []

# PHP
# Default Value: E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED
# Development Value: E_ALL
# Production Value: E_ALL & ~E_DEPRECATED & ~E_STRICT
default['php']['error_reporting'] = 'E_ALL'
default['php']['display_errors'] = 'Off'
default['php']['log_errors'] = 'On'
default['php']['post_max_size'] = '96M'
default['php']['upload_max_filesize'] = '64M'
default['php']['max_file_uploads'] = '20'
default['php']['memory_limit'] = '256M'

# OPcache
default['opcache']['enabled'] = '1'
default['opcache']['memory_consumption'] = '128'
default['opcache']['interned_strings_buffer'] = '8'
default['opcache']['max_accelerated_files'] = '4000'
default['opcache']['revalidate_freq'] = '60'
default['opcache']['fast_shutdown'] = '1'
default['opcache']['enable_cli'] = '1'
default['opcache']['consistency_checks'] = '0'

# Node
default['nodejs']['install_method'] = 'source'
# default["nodejs"]["version"] = "4.2.4"
# default['nodejs']['source']['checksum'] = "4ee244ffede7328d9fa24c3024787e71225b7abaac49fe2b30e68b27460c10ec"
# default["nodejs"]["npm"]["install_method"] = "source"
