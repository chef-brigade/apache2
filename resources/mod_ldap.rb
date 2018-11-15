#
# Cookbook:: apache2
# Resource:: apache2_mod_ldap
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
property :location, String,
         default: '/ldap-status'
property :set_handler, String,
         default: 'ldap-status'
property :require, String,
         default: 'local'
action :create do
  template ::File.join(apache_dir, 'mods-available', 'ldap.conf') do
    source 'mods/ldap.conf.erb'
    cookbook 'apache2'
    variables(
      location: new_resource.location,
      set_handler: new_resource.set_handler,
      require: new_resource.require
    )
  end
end

action_class do
  include Apache2::Cookbook::Helpers
end
