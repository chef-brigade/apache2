#
# Cookbook:: apache2
# Resource:: apache2_web_app
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
property :template, String,
         default: 'web_app.conf.erb',
         description: 'Template name'
property :cookbook, String,
         default: 'apache2',
         description: 'Cookbok to source the template from'
property :local, [true, false],
          default: false,
          description: 'Load a template from a local path. By default, the chef-client
loads templates from a cookbook’s /templates directory. When this property is
set to true, use the source property to specify the path to a template on the
local node.'
property :local, [true, false],
         default: false,
         description: ''
property :enable, [true, false],
         default: true,
         description: 'enable or disable the site'
property :server_port, Integer,
         default: 80,
         description: 'Port to listen on'
property :root_group, String,
default: lazy { default_apache_root_group },
description: ''
property :parameters, Hash,
description: ''

action :enable do
  apache2_module 'rewrite'

  apache2_module 'deflate'

  apache2_module 'headers' do
    apache_service_notification :restart
  end

  template "#{apache_dir}/sites-available/#{new_resource.name}.conf" do
    source new_resource.template
    local new_resource.local
    cookbook 'apache2'
    owner 'root'
    group new_resource.root_group
    mode '0644'
    cookbook new_resource.cookbook
    variables(
      name: new_resource.name,
      params: new_resource.params
    )
    if ::File.exist?("#{apache_dir}/sites-enabled/#{new_resource.name}.conf")
      notifies :reload, 'service[apache2]', :delayed
    end
  end

  apache_site new_resource.name
end
