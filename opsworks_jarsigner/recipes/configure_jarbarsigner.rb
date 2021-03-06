#
# Cookbook Name:: opsworks_jarsigner
# Recipe:: configure_jarsigner
#
# Copyright (C) 2014 YOUR_NAME
# 
# All rights reserved - Do Not Redistribute
#
# include_recipe File.join(File.dirname(__FILE__), '../providers/jarsigner_service')


directory "/work" do
  owner "root"
  group "root"
  mode "0000"
  action :create
  not_if {::File.directory?('/work')}
end

if !::File.directory?('/opt/jarsigner')
  directory '/opt/jarsigner' do
    owner "root"
    group "root"
    mode "0755"
    action :create
  end
  s3_file "/opt/jarsigner/tnt-jar-bar-signer.tar.gz" do
    remote_path "tnt-jarsigner/tnt-jar-bar-signer.tar.gz"
    bucket "tnt-build-release"
    if node[:opsworks_jarsigner][:access_key_id]
      aws_access_key_id node[:opsworks_jarsigner][:access_key_id]
      aws_secret_access_key node[:opsworks_jarsigner][:access_key_secret]
    end
    action :create
    owner "root"
    group "root"
  end
end

if !::File.directory?('/opt/bbndk-2.1.0')
  s3_file "/opt/bbndk-2.1.0.tar" do
    remote_path "blackberry-ndk/bbndk-2.1.0.tar"
    bucket "tnt-build-release"
    if node[:opsworks_jarsigner][:access_key_id]
      aws_access_key_id node[:opsworks_jarsigner][:access_key_id]
      aws_secret_access_key node[:opsworks_jarsigner][:access_key_secret]
    end
    action :create
    owner "root"
    group "root"
  end
  bash "extract bbndk-2.1.0" do
    user "root"
    cwd "/opt"
    code <<-EOH
      tar xvf bbndk-2.1.0.tar
    EOH
    only_if {::File.exists?('/opt/bbndk-2.1.0.tar')}
  end
  bash "update_bashrc_bashprofile_for_bbndk" do
    user "root"
    cwd "/opt/bbndk-2.1.0/"
    code <<-EOH
      cat bbndk-env.sh >> ~/.bashrc
      cat bbndk-env.sh >> ~/.bash_profile
    EOH
    only_if {::File.exists?('/opt/bbndk-2.1.0/bbndk-env.sh')}
    if `grep -i 'bbndk' ~/.bashrc` !=""
      action :nothing
    end
  end
end

if !::File.exists?('/opt/jarsigner/run.sh')
	execute "extract jarbarsigner" do
	  cwd "/opt/jarsigner"
	  command "tar xvzf tnt-jar-bar-signer.tar.gz"
	  only_if {::File.directory?('/opt/jarsigner')}
	end.run_action(:run)
end

directory '/root/.rim' do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

bash "configure_rim" do 
  user "root"
  code <<-EOH
    mv /opt/jarsigner/bb_cert.tar /root/.rim/
  EOH
  not_if {::File.exists?('/root/.rim/bb_cert.tar')}
end

bash "extract_bb_cert" do
  user "root"
  cwd "/root/.rim"
  code <<-EOH
    tar xvf bb_cert.tar
  EOH
  not_if {::File.exists?('/root/.rim/barsigner.db')}
end


bash "update_bashrc_bashprofile_for_android" do
  user "root"
  cwd "/etc/profile.d/"
  code <<-EOH
    cat android-sdk.sh >> ~/.bashrc
    cat android-sdk.sh >> ~/.bash_profile
  EOH
  only_if {::File.exists?('/etc/profile.d/android-sdk.sh')}
  if `grep -i 'android' ~/.bashrc` !=""
    action :nothing
  end
end

opsworks_jarsigner_service "jarsigner" do
  process_name "java"
  action :start
end
# opsworks_jarsigner_jarsigner "jarsigner" do
#   process_name "java"
#   action :stop
# end