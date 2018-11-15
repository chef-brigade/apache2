#
# Cookbook:: apache2
# Resource:: apache2_mod_mime_magic
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

property :mime_magic_file, String,
         default: lazy { default_mime_magic_file },
         description: ''

action :create do
  template ::File.join(apache_dir, 'mods-available', 'mime_magic.conf') do
    source 'mods/mime_magic.conf.erb'
    cookbook 'apache2'
    variables(
      mime_magic_file: new_resource.mime_magic_file
    )
  end
end

action_class do
  include Apache2::Cookbook::Helpers
end
