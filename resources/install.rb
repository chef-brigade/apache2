#
# Cookbook:: apache2
# Resource:: apache2_conf
#
# Copyright:: 2008-2017, Chef Software, Inc.
# Copyright:: 2018, Webb Agile Solutions Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include Apache2::Cookbook::Helpers

property :root_group, String,
         default: lazy { default_apache_root_group },
         description: 'Group that the root user on the box runs as. Defaults to platform specific locations, see libraries/helpers.rb'
property :apache_user, String,
         default: lazy { default_apache_user },
         description: 'Set to override the default apache2 user. Defaults to platform specific locations, see libraries/helpers.rb'
property :apache_group, String,
         default: lazy { default_apache_group },
         description: 'Set to override the default apache2 user. Defaults to platform specific locations, see libraries/helpers.rb'
property :log_dir, String,
         default: lazy { default_log_dir },
         description: 'Log directory location. Defaults to platform specific locations, see libraries/helpers.rb'
property :error_log, String,
         default: lazy { default_error_log },
         description: 'Error log location. Defaults to platform specific locations, see libraries/helpers.rb'
property :log_level, String,
         default: 'warn',
         description: 'log level for apache2'
property :apache_locale, String,
         default: 'system',
         description: 'Locale for apache2, defaults to the system locale'
property :status_url, String,
         default: 'http://localhost:80/server-status',
         description: 'URL for status checks'
property :httpd_t_timeout, Integer,
         default: 10,
         description: 'Service timeout setting. Defaults to 10 seconds'
property :mpm, String,
         default: lazy { default_mpm },
         description: 'Multi-processing Module. Defaults to platform specific locations, see libraries/helpers.rb'
property :listen, [String, Array],
         default: %w(80 443),
         description: 'Port to listen on. Defaults to both 80 & 443'
property :keep_alive, String,
         equal_to: %w(On Off),
         default: 'On',
         description: 'Persistent connection feature of HTTP/1.1 provide long-lived HTTP sessions'
property :max_keep_alive_requests, Integer,
         default: 100,
         description: 'MaxKeepAliveRequests'
property :keep_alive_timeout, Integer,
         default: 5,
         description: 'KeepAliveTimeout'
property :docroot_dir, String,
         default: lazy { default_docroot_dir },
         description: 'Apache document root. Defaults to platform specific locations, see libraries/helpers.rb'
property :run_dir, String,
         default: lazy { default_run_dir },
         description: 'Location for APACHE_RUN_DIR. Defaults to platform specific locations, see libraries/helpers.rb'
property :access_file_name, String,
         defualt: '.htaccess',
         description: 'String: Access filename'
property :sysconfig_additional_params, Hash,
         default: {},
         description: 'Hash of additional sysconfig parameters to apply to the system'

action :install do
  package [apache_pkg, perl_pkg]
  package 'perl-Getopt-Long-Descriptive' if platform?('fedora')

  directory apache_dir do
    mode '0751'
    owner 'root'
    group new_resource.root_group
  end

  %w(sites-available sites-enabled mods-available mods-enabled conf-available conf-enabled).each do |dir|
    directory "#{apache_dir}/#{dir}" do
      mode '0750'
      owner 'root'
      group new_resource.root_group
    end
  end

  %w( conf.d conf.modules.d ).each do |dir|
    directory "#{apache_dir}/#{dir}" do
      recursive true
      action :delete
    end
  end

  directory new_resource.log_dir do
    mode '0750'
    recursive true
  end

  %w(a2ensite a2dissite a2enmod a2dismod a2enconf a2disconf).each do |modscript|
    link "/usr/sbin/#{modscript}" do
      action :delete
      only_if { ::File.symlink?("/usr/sbin/#{modscript}") }
    end

    template "/usr/sbin/#{modscript}" do
      source "#{modscript}.erb"
      cookbook 'apache2'
      mode '0700'
      owner 'root'
      variables(
        apachectl: apachectl,
        apache_dir: apache_dir
      )
      group new_resource.root_group
      action :create
    end
  end

  unless platform_family?('debian')
    cookbook_file '/usr/local/bin/apache2_module_conf_generate.pl' do
      source 'apache2_module_conf_generate.pl'
      cookbook 'apache2'
      mode '0750'
      owner 'root'
      group new_resource.root_group
    end

    execute 'generate-module-list' do
      command "/usr/local/bin/apache2_module_conf_generate.pl #{lib_dir} #{apache_dir}/mods-available"
      action :nothing
    end
  end

  if platform_family?('freebsd')
    directory "#{apache_dir}/Includes" do
      action :delete
      recursive true
    end

    directory "#{apache_dir}/extra" do
      action :delete
      recursive true
    end
  end

  if platform_family?('suse')
    directory "#{apache_dir}/vhosts.d" do
      action :delete
      recursive true
    end

    %w(charset.conv default-vhost.conf default-server.conf default-vhost-ssl.conf errors.conf listen.conf mime.types mod_autoindex-defaults.conf mod_info.conf mod_log_config.conf mod_status.conf mod_userdir.conf mod_usertrack.conf uid.conf).each do |file|
      file "#{apache_dir}/#{file}" do
        action :delete
        backup false
      end
    end
  end

  directory "#{apache_dir}/ssl" do
    mode '0750'
    owner 'root'
    group new_resource.root_group
  end

  directory cache_dir do
    mode '0750'
    owner 'root'
    group new_resource.root_group
  end

  directory lock_dir do
    mode '0750'
    if node['platform_family'] == 'debian'
      owner new_resource.apache_user
    else
      owner 'root'
    end
    group new_resource.root_group
  end

  template "/etc/sysconfig/#{apache_platform_service_name}" do
    source 'etc-sysconfig-httpd.erb'
    cookbook 'apache2'
    owner 'root'
    group new_resource.root_group
    mode '0644'
    variables(
      apache_binary: apache_binary,
      apache_dir: apache_dir
    )
    only_if { platform_family?('rhel', 'amazon', 'fedora', 'suse') }
  end

  template "#{apache_dir}/envvars" do
    source 'envvars.erb'
    cookbook 'apache2'
    owner 'root'
    group new_resource.root_group
    mode '0644'
    variables(
      lock_dir: lock_dir,
      log_dir: new_resource.log_dir,
      apache_user: new_resource.apache_user,
      apache_group: new_resource.apache_group,
      pid_file: apache_pid_file,
      apache_locale: new_resource.apache_locale,
      status_url: new_resource.status_url
    )
    only_if { platform_family?('debian') }
  end

  apache2_config 'apache2.conf' do
    access_file_name new_resource.access_file_name
    log_dir new_resource.log_dir
    error_log new_resource.error_log
    log_level new_resource.log_level
    apache_user new_resource.apache_user
    apache_group new_resource.apache_group
    keep_alive new_resource.keep_alive
    max_keep_alive_requests new_resource.max_keep_alive_requests
    keep_alive_timeout new_resource.keep_alive_timeout
    docroot_dir new_resource.docroot_dir
  end

  apache2_conf 'security'
  apache2_conf 'charset'

  template 'ports.conf' do
    path     "#{apache_dir}/ports.conf"
    cookbook 'apache2'
    mode     '0644'
    variables(
      listen: new_resource.listen
    )
  end

  # MPM Support Setup
  case new_resource.mpm
  when 'event'
    if platform_family?('suse')
      package %w(apache2-prefork apache2-worker) do
        action :remove
      end

      package 'apache2-event'
    else
      %w(mpm_prefork mpm_worker).each do |mpm|
        apache2_module mpm do
          action :disable
        end
      end

      apache2_module 'mpm_event' do
        apache_service_notification :restart
      end
    end

  when 'prefork'
    if platform_family?('suse')
      package %w(apache2-event apache2-worker) do
        action :remove
      end

      package 'apache2-prefork'
    else
      %w(mpm_event mpm_worker).each do |mpm|
        apache2_module mpm do
          action :disable
        end
      end

      apache2_module 'mpm_prefork' do
        apache_service_notification :restart
      end
    end

  when 'worker'
    if platform_family?('suse')
      package %w(apache2-event apache2-prefork) do
        action :remove
      end

      package 'apache2-worker'
    else
      %w(mpm_prefork mpm_event).each do |mpm|
        apache2_module mpm do
          action :disable
        end
      end

      apache2_module 'mpm_worker' do
        apache_service_notification :restart
      end
    end
  end

  default_modules.each do |mod|
    apache2_module mod
  end

  service 'apache2' do
    service_name apache_platform_service_name
    supports [:start, :restart, :reload, :status]
    action [:enable, :start]
    only_if "#{apache_binary} -t", environment: { 'APACHE_LOG_DIR' => new_resource.log_dir }, timeout: new_resource.httpd_t_timeout
  end
end

action_class do
  include Apache2::Cookbook::Helpers
end
