
domain_name="domain1"
domains_dir = node['hopsworks']['domains_dir']
theDomain="#{domains_dir}/#{domain_name}"


case node['platform']
when "ubuntu"
 if node['platform_version'].to_f <= 14.04
   node.override['hopsworks']['systemd'] = "false"
 end
end

if node['hopsworks']['systemd'] === "true"
  systemd = true
else
  systemd = false
end


include_recipe "java"

##
## default['rb']
##

# If the install.rb recipe was in a different run, the location of the install dir may
# not be correct. install_dir is updated by install.rb, but not persisted, so we need to
# reset it
if node['glassfish']['install_dir'].include?("versions") == false
  node.override['glassfish']['install_dir'] = "#{node['glassfish']['install_dir']}/glassfish/versions/current"
end

private_ip=my_private_ip()
public_ip=my_public_ip()
hopsworks_db = "hopsworks"
realmname="kthfsrealm"

begin
  elastic_ip = private_recipe_ip("elastic","default")
rescue
  elastic_ip = ""
  Chef::Log.warn "could not find the elastic server ip for HopsWorks!"
end

begin
  hopsworks_ip = private_recipe_ip("hopsworks","default")
rescue
  hopsworks_ip = ""
  Chef::Log.warn "could not find the hopsworks server ip for HopsWorks!"
end


begin
  spark_history_server_ip = private_recipe_ip("hadoop_spark","historyserver")
rescue
  spark_history_server_ip = node['hostname']
  Chef::Log.warn "could not find the spark history server ip for HopsWorks!"
end

begin
  jhs_ip = private_recipe_ip("hops","jhs")
rescue
  jhs_ip = node['hostname']
  Chef::Log.warn "could not find the MR job history server ip!"
end

begin
  rm_ip = private_recipe_ip("hops","rm")
rescue
  rm_ip = node['hostname']
  Chef::Log.warn "could not find the Resource Manager ip!"
end

begin
  rm_port = node['hops']['rm']['http_port']
rescue
  rm_port = 8088
  Chef::Log.warn "could not find the Resource Manager Port!"
end

begin
  logstash_ip = private_recipe_ip("hopslog","default")
rescue
  logstash_ip = node['hostname']
  Chef::Log.warn "could not find the Logstash ip!"
end

begin
  logstash_port = node['logstash']['http']['port']
rescue
  logstash_port = 3456
  Chef::Log.warn "could not find the Logstash Port!"
end

begin
  livy_ip = private_recipe_ip("livy","default")
rescue
  livy_ip = node['hostname']
  Chef::Log.warn "could not find livy server ip!"
end

begin
  epipe_ip = private_recipe_ip("epipe","default")
rescue
  epipe_ip = node['hostname']
  Chef::Log.warn "could not find th epipe server ip!"
end

begin
  zk_ip = private_recipe_ip("kzookeeper","default")
rescue
  zk_ip = node['hostname']
  Chef::Log.warn "could not find th zk server ip!"
end

begin
  kafka_ip = private_recipe_ip("kkafka","default")
rescue
  kafka_ip = node['hostname']
  Chef::Log.warn "could not find th kafka server ip!"
end

begin
  drelephant_ip = private_recipe_ip("drelephant","default")
rescue
  drelephant_ip = node['hostname']
  Chef::Log.warn "could not find the dr elephant server ip!"
end

begin
  dela_ip = private_recipe_ip("dela","default")
rescue
  dela_ip = node['hostname']
  Chef::Log.warn "could not find the dela server ip!"
end

begin
  kibana_ip = private_recipe_ip("hopslog","default")
rescue
  kibana_ip = node['hostname']
  Chef::Log.warn "could not find the logstash server ip!"
end

begin
  grafana_ip = private_recipe_ip("hopsmonitor","default")
  influxdb_ip = private_recipe_ip("hopsmonitor","default")
rescue
  grafana_ip = node['hostname']
  influxdb_ip = node['hostname']
  Chef::Log.warn "could not find the hopsmonitor server ip!"
end

begin
  hiveserver_ip = private_recipe_ip("hive2","default")
rescue
  hiveserver_ip = node['hostname']
  Chef::Log.warn "could not find the Hive server ip!"
end

begin
  python_kernel = "#{node['jupyter']['python']}".downcase
rescue
  python_kernel = "true"
  Chef::Log.warn "could not find the jupyter/python variable defined as an attribute!"
end


vagrant_enabled = 0
if node['hopsworks']['user'] == "vagrant"
  vagrant_enabled = 1
end

tables_path = "#{domains_dir}/tables.sql"
views_path = "#{domains_dir}/views.sql"
rows_path = "#{domains_dir}/rows.sql"

hopsworks_grants "hopsworks_tables" do
  tables_path  "#{tables_path}"
  views_path  "#{views_path}"
  rows_path  "#{rows_path}"
  action :nothing
end

template views_path do
  source File.basename("#{views_path}") + ".erb"
  owner node['glassfish']['user']
  mode 0750
  action :create
  variables({
               :private_ip => private_ip
              })
end

# Need to delete the sql file so that the action is triggered
file tables_path do
  action :delete
  ignore_failure true
end

Chef::Log.info("Could not find previously defined #{tables_path} resource")
template tables_path do
  source File.basename("#{tables_path}") + ".erb"
  owner node['glassfish']['user']
  mode 0750
  action :create
  variables({
                :private_ip => private_ip
              })
    notifies :create_tables, 'hopsworks_grants[hopsworks_tables]', :immediately
end

timerTable = "ejbtimer_mysql.sql"
timerTablePath = "#{Chef::Config['file_cache_path']}/#{timerTable}"

# Need to delete the sql file so that the create_timers action is triggered
file timerTablePath do
  action :delete
  ignore_failure true
end

hopsworks_grants "timers_tables" do
  tables_path  "#{timerTablePath}"
  rows_path  ""
  action :nothing
end

template timerTablePath do
  source File.basename("#{timerTablePath}") + ".erb"
  owner node['glassfish']['user']
  mode 0750
  action :create
  notifies :create_timers, 'hopsworks_grants[timers_tables]', :immediately
end

require 'resolv'
hostf = Resolv::Hosts.new
dns = Resolv::DNS.new

hosts = ""

for h in node['kagent']['default']['private_ips']

  # Try and resolve hostname first using /etc/hosts, then use DNS
  begin
    hname = hostf.getname(h)
  rescue
    begin
      hname = dns.getname(h)
    rescue
      raise "Cannot resolve the hostname for IP address: #{h}"
    end
  end

  hosts += "('" + hname.to_s + "','" + h + "')" + ","
end
if h.length > 0
  hosts = hosts.chop!
end

hops_rpc_tls_val = "false"
if node['hops']['rpc']['ssl'].eql? "true"
  hops_rpc_tls_val = "true"
end

template "#{rows_path}" do
   source File.basename("#{rows_path}") + ".erb"
   owner node['glassfish']['user']
   mode 0755
   action :create
    variables({
                :hosts => hosts,
                :epipe_ip => epipe_ip,
                :livy_ip => livy_ip,
                :jhs_ip => jhs_ip,
                :rm_ip => rm_ip,
                :rm_port => rm_port,
                :logstash_ip => logstash_ip,
                :logstash_port => logstash_port,
                :spark_history_server_ip => spark_history_server_ip,
                :hopsworks_ip => hopsworks_ip,
                :elastic_ip => elastic_ip,
                :spark_dir => node['hadoop_spark']['dir'] + "/spark",
                :spark_user => node['hadoop_spark']['user'],
                :hadoop_dir => node['hops']['dir'] + "/hadoop",
                :yarn_user => node['hops']['yarn']['user'],
                :yarn_ui_ip => public_recipe_ip("hops","rm"),
                :yarn_ui_port => node['hops']['rm']['http_port'],
                :hdfs_ui_ip => public_recipe_ip("hops","nn"),
                :hdfs_ui_port => node['hops']['nn']['http_port'],
                :hopsworks_user => node['hopsworks']['user'],
                :hdfs_user => node['hops']['hdfs']['user'],
                :mr_user => node['hops']['mr']['user'],
                :flink_dir => node['flink']['dir'] + "/flink",
                :flink_user => node['flink']['user'],
                :zeppelin_dir => node['zeppelin']['dir'] + "/zeppelin",
                :zeppelin_user => node['zeppelin']['user'],
                :ndb_dir => node['ndb']['dir'] + "/mysql-cluster",
                :mysql_dir => node['mysql']['dir'] + "/mysql",
                :elastic_dir => node['elastic']['dir'] + "/elastic",
                :hopsworks_dir => domains_dir,
                :twofactor_auth => node['hopsworks']['twofactor_auth'],
                :twofactor_exclude_groups => node['hopsworks']['twofactor_exclude_groups'],
                :hops_rpc_tls => hops_rpc_tls_val,
                :cert_mater_delay => node['hopsworks']['cert_mater_delay'],
                :elastic_user => node['elastic']['user'],
                :yarn_default_quota => node['hopsworks']['yarn_default_quota_mins'].to_i * 60,
                :hdfs_default_quota => node['hopsworks']['hdfs_default_quota_mbs'].to_i,
                :hive_default_quota => node['hopsworks']['hive_default_quota_mbs'].to_i,
                :max_num_proj_per_user => node['hopsworks']['max_num_proj_per_user'],
		:file_preview_image_size => node['hopsworks']['file_preview_image_size'],
		:file_preview_txt_size => node['hopsworks']['file_preview_txt_size'],
                :zk_ip => zk_ip,
                :java_home => node['java']['java_home'],
                :kafka_ip => kafka_ip,
                :kafka_num_replicas => node['hopsworks']['kafka_num_replicas'],
                :kafka_num_partitions => node['hopsworks']['kafka_num_partitions'],
                :drelephant_port => node['drelephant']['port'],
                :drelephant_db => node['drelephant']['db'],
                :drelephant_ip => drelephant_ip,
                :kafka_user => node['kkafka']['user'],
                :kibana_ip => kibana_ip,
                :python_kernel => python_kernel,
                :grafana_ip => grafana_ip,
                :influxdb_ip => influxdb_ip,
                :influxdb_port => node['influxdb']['http']['port'],
                :influxdb_user => node['influxdb']['db_user'],
                :influxdb_password => node['influxdb']['db_password'],
                :graphite_port => node['influxdb']['graphite']['port'],
                :cuda_dir => node['cuda']['base_dir'],
                :anaconda_dir => node['conda']['base_dir'],
                :org_name => node['hopsworks']['org_name'],
                :org_domain => node['hopsworks']['org_domain'],
                :org_email => node['hopsworks']['org_email'],
                :org_country_code => node['hopsworks']['org_country_code'],
                :org_city => node['hopsworks']['org_city'],
                :vagrant_enabled => vagrant_enabled,
                :public_ip => public_ip,
                :monitor_max_status_poll_try => node['hopsworks']['monitor_max_status_poll_try'],
                :dela_enabled => node['hopsworks']['dela']['enabled'],
                :dela_ip => dela_ip,
                :dela_port => node['dela']['http_port'],
                :dela_cluster_http_port => node['hopsworks']['dela']['cluster_http_port'],
                :dela_hopsworks_public_port => node['hopsworks']['dela']['public_hopsworks_port'],
                :recovery_path => node['hopsworks']['recovery_path'],
                :verification_path => node['hopsworks']['verification_path'],
                :hivessl_hostname => hiveserver_ip + ":#{node['hive2']['portssl']}",
                :hiveext_hostname => hiveserver_ip + ":#{node['hive2']['port']}",
                :hive_warehouse => "#{node['hive2']['hopsfs_dir']}/warehouse",
                :hive_scratchdir => node['hive2']['scratch_dir']
           })
   notifies :insert_rows, 'hopsworks_grants[hopsworks_tables]', :immediately
end



###############################################################################
# config glassfish
###############################################################################

username=node['hopsworks']['admin']['user']
password=node['hopsworks']['admin']['password']
admin_port = 4848
mysql_host = private_recipe_ip("ndb","mysqld")


jndiDB = "jdbc/hopsworks"
timerDB = "jdbc/hopsworksTimers"

asadmin = "#{node['glassfish']['base_dir']}/versions/current/bin/asadmin"
admin_pwd="#{domains_dir}/#{domain_name}_admin_passwd"

password_file = "#{domains_dir}/#{domain_name}_admin_passwd"

login_cnf="#{domains_dir}/#{domain_name}/config/login.conf"
log4j_cnf="#{domains_dir}/#{domain_name}/config/log4j.properties"

file "#{login_cnf}" do
   action :delete
end

template "#{login_cnf}" do
  cookbook 'hopsworks'
  source "login.conf.erb"
  owner node['glassfish']['user']
  group node['glassfish']['group']
  mode "0600"
end

file "#{log4j_cnf}" do
   action :delete
end

template "#{log4j_cnf}" do
  cookbook 'hopsworks'
  source "log4j.properties.erb"
  owner node['glassfish']['user']
  group node['glassfish']['group']
end


hopsworks_grants "reload_sysv" do
 tables_path  ""
 rows_path  ""
 action :reload_sysv
end


glassfish_secure_admin domain_name do
  domain_name domain_name
  password_file "#{domains_dir}/#{domain_name}_admin_passwd"
  username username
  admin_port admin_port
  secure false
  action :enable
end


#end



props =  {
  'datasource-jndi' => jndiDB,
  'password-column' => 'password',
  'group-table' => 'hopsworks.users_groups',
  'user-table' => 'hopsworks.users',
  'group-name-column' => 'group_name',
  'user-name-column' => 'email',
  'group-table-user-name-column' => 'email',
  'encoding' => 'Hex',
  'digestrealm-password-enc-algorithm' => 'SHA-256',
  'digest-algorithm' => 'SHA-256'
}

 glassfish_auth_realm "#{realmname}" do
   realm_name "#{realmname}"
   jaas_context "jdbcRealm"
   properties props
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
   classname "com.sun.enterprise.security.auth.realm.jdbc.JDBCRealm"
 end


 cProps = {
     'datasource-jndi' => jndiDB,
     'password-column' => 'password',
     'encoding' => 'Hex',
     'group-table' => 'hopsworks.users_groups',
     'user-table' => 'hopsworks.users',
     'group-name-column' => 'group_name',
     'user-name-column' => 'email',
     'group-table-user-name-column' => 'email',
     'otp-secret-column' => 'secret',
     'two-factor-column' => 'two_factor',
     'user-status-column' => 'status',
     'yubikey-table' => 'hopsworks.yubikey',
     'variables-table' => 'hopsworks.variables'
 }

 glassfish_auth_realm "cauthRealm" do
   realm_name "cauthRealm"
   jaas_context "cauthRealm"
   properties cProps
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
   classname "se.kth.bbc.crealm.CustomAuthRealm"
 end



glassfish_asadmin "set server-config.security-service.default-realm=cauthRealm" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
end


# Jobs in Hopsworks use the Timer service
glassfish_asadmin "set server-config.ejb-container.ejb-timer-service.timer-datasource=#{timerDB}" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
end

glassfish_asadmin "set server.http-service.virtual-server.server.property.send-error_1=\"code=404 path=#{domains_dir}/#{domain_name}/docroot/404.html reason=Resource_not_found\"" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
end


glassfish_asadmin "set server.network-config.protocols.protocol.http-listener-2.ssl.ssl3-enabled=false" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
end

glassfish_asadmin "set server.network-config.protocols.protocol.sec-admin-listener.ssl.ssl3-enabled=false" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
end

# Disable SSLv3 on iiop-listener.ssl
#glassfish_asadmin "set server.iiop-service.iiop-listener.SSL.ssl.ssl3-enabled=false" do
#   domain_name domain_name
#   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
#   username username
#   admin_port admin_port
#   secure false
#end

# Disable SSLv3 on iiop-muth_listener.ssl
#glassfish_asadmin "set server.iiop-service.iiop-listener.SSL_MUTUALAUTH.ssl.ssl3-enabled=false" do
#   domain_name domain_name
#   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
#   username username
#   admin_port admin_port
#   secure false
#end

# Restrict ciphersuite
glassfish_asadmin "set configs.config.server-config.network-config.protocols.protocol.http-listener-2.ssl.ssl3-tls-ciphers=#{node['glassfish']['ciphersuite']}" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
end

# Restrict ciphersuite
glassfish_asadmin "set configs.config.server-config.network-config.protocols.protocol.sec-admin-listener.ssl.ssl3-tls-ciphers=#{node['glassfish']['ciphersuite']}" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
end

# Restrict ciphersuite
# glassfish_asadmin "set configs.config.server-config.iiop-service.iiop-listener.SSL_MUTUALAUTH.ssl.ssl3-tls-ciphers=#{node['glassfish']['ciphersuite']}" do
#    domain_name domain_name
#    password_file "#{domains_dir}/#{domain_name}_admin_passwd"
#    username username
#    admin_port admin_port
#    secure false
# end


# Needed by Shibboleth
glassfish_asadmin "create-network-listener --protocol http-listener-1 --listenerport 8009 --jkenabled true jk-connector" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
  not_if "#{asadmin} --user #{username} --passwordfile #{admin_pwd}  list-http-listeners | grep 'jk-connect'"
end

# Needed by Shibboleth
glassfish_asadmin "set-log-levels org.glassfish.grizzly.http.server.util.RequestUtils=SEVERE" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
end


#
# Enable Single Sign on
#

glassfish_asadmin "set server-config.http-service.virtual-server.server.property.sso-enabled='true'" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
end

# glassfish_asadmin "set default-config.http-service.virtual-server.server.property.sso-enabled='true'" do
#    domain_name domain_name
#    password_file "#{domains_dir}/#{domain_name}_admin_passwd"
#    username username
#    admin_port admin_port
#    secure false
# end


# glassfish_asadmin "set cluster.availability-service.web-container-availability.sso-failover-enabled=true" do
#    domain_name domain_name
#    password_file "#{domains_dir}/#{domain_name}_admin_passwd"
#    username username
#    admin_port admin_port
#    secure false
# end


glassfish_asadmin "set server-config.http-service.virtual-server.server.property.sso-max-inactive-seconds=300" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
end

glassfish_asadmin "set server-config.http-service.virtual-server.server.property.sso-reap-interval-seconds=60" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
end

glassfish_asadmin "set server-config.http-service.virtual-server.server.property.ssoCookieSecure=no" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
end

glassfish_asadmin "set default-config.http-service.virtual-server.server.property.ssoCookieSecure=no" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
end

# glassfish_asadmin "set resources.managed-executor-service.concurrent/__defaultManagedExecutorService.core-pool-size=1500" do
#    domain_name domain_name
#    password_file "#{domains_dir}/#{domain_name}_admin_passwd"
#    username username
#    admin_port admin_port
#    secure false
# end

# glassfish_asadmin "set resources.managed-executor-service.concurrent/__defaultManagedExecutorService.maximum-pool-size=2800" do
#    domain_name domain_name
#    password_file "#{domains_dir}/#{domain_name}_admin_passwd"
#    username username
#    admin_port admin_port
#    secure false
# end

# glassfish_asadmin "set resources.managed-executor-service.concurrent/__defaultManagedExecutorService.task-queue-capacity=10000" do
#    domain_name domain_name
#    password_file "#{domains_dir}/#{domain_name}_admin_passwd"
#    username username
#    admin_port admin_port
#    secure false
# end

glassfish_asadmin "create-managed-executor-service --enabled=true --longrunningtasks=true --corepoolsize=10 --maximumpoolsize=200 --keepaliveseconds=60 --taskqueuecapacity=10000 concurrent/kagentExecutorService" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   secure false
  not_if "#{asadmin} --user #{username} --passwordfile #{admin_pwd}  list-managed-executor-services | grep 'kagent'"
end



# Needed by AJP and Shibboleth - https://github.com/payara/Payara/issues/350


# cluster="hopsworks"

# glassfish_asadmin "create-cluster #{cluster}" do
#    domain_name domain_name
#    password_file "#{domains_dir}/#{domain_name}_admin_passwd"
#    username username
#    admin_port admin_port
#    secure false
# end

# glassfish_asadmin "#asadmin --host das_host --port das_port create-local-instance --node #{hostname} instance_#{hostname}" do
#    domain_name domain_name
#    password_file "#{domains_dir}/#{domain_name}_admin_passwd"
#    username username
#    admin_port admin_port
#    secure false
# end


# glassfish_asadmin "create-local-instance --cluster #{cluster} instance1" do
#    domain_name domain_name
#    password_file "#{domains_dir}/#{domain_name}_admin_passwd"
#    username username
#    admin_port admin_port
#    secure false
# end


# TODO - set ejb timer source as a cluster called 'hopsworks'
# https://docs.oracle.com/cd/E18930_01/html/821-2418/beahw.html#gktqo
# glassfish_asadmin "set configs.config.hopsworks-config.ejb-container.ejb-timer-service.timer-datasource=#{timerDB}" do
#    domain_name domain_name
#    password_file "#{domains_dir}/#{domain_name}_admin_passwd"
#    username username
#    admin_port admin_port
#    secure false
# end


if node['hopsworks']['email_password'].eql? "password"

  bash 'gmail' do
    user "root"
    code <<-EOF
      cd #{Chef::Config['file_cache_path']}
      rm -f #{Chef::Config['file_cache_path']}/hopsworks.email
      wget #{node['hopsworks']['gmail']['placeholder']}
      cat #{Chef::Config['file_cache_path']}/hopsworks.email | base64 -d > #{Chef::Config['file_cache_path']}/hopsworks.encoded
      chmod 775 #{Chef::Config['file_cache_path']}/hopsworks.encoded
    EOF
  end

end



hopsworks_mail "gmail" do
   domain_name domain_name
   password_file "#{domains_dir}/#{domain_name}_admin_passwd"
   username username
   admin_port admin_port
   action :jndi
end



node.override['glassfish']['asadmin']['timeout'] = 400

glassfish_deployable "hopsworks-ear" do
  component_name "hopsworks-ear"
  target "server"
  url node['hopsworks']['ear_url']
  version node['hopsworks']['version']
  domain_name domain_name
  password_file "#{domains_dir}/#{domain_name}_admin_passwd"
  username username
  admin_port admin_port
  secure false
  action :deploy
  async_replication false
  retries 1
  not_if "#{asadmin} --user #{username} --passwordfile #{admin_pwd}  list-applications --type ejb | grep -w 'hopsworks-ear'"
end




glassfish_deployable "hopsworks" do
  component_name "hopsworks-web"
  target "server"
  url node['hopsworks']['war_url']
  version node['hopsworks']['version']
  context_root "/hopsworks"
  domain_name domain_name
  password_file "#{domains_dir}/#{domain_name}_admin_passwd"
  username username
  admin_port admin_port
  secure false
  action :deploy
  async_replication false
  retries 1
  not_if "#{asadmin} --user #{username} --passwordfile #{admin_pwd}  list-applications --type ejb | grep -v hopsworks-ear | grep hopsworks"
end


glassfish_deployable "hopsworks-ca" do
  component_name "hopsworks-ca"
  target "server"
  url node['hopsworks']['ca_url']
  version node['hopsworks']['version']
  domain_name domain_name
  password_file "#{domains_dir}/#{domain_name}_admin_passwd"
  username username
  admin_port admin_port
  secure false
  action :deploy
  async_replication false
  retries 1
  not_if "#{asadmin} --user #{username} --passwordfile #{admin_pwd}  list-applications --type ejb | grep -w hopsworks-ca"
end

template "/bin/hopsworks-2fa" do
    source "hopsworks-2fa.erb"
    owner "root"
    mode 0700
    action :create
 end

hopsworks_certs "generate-certs" do
  action :generate
end

template "#{domains_dir}/#{domain_name}/bin/condasearch.sh" do
  source "condasearch.sh.erb"
  owner node['glassfish']['user']
  group node['glassfish']['group']
  mode 0750
  action :create
end

template "#{domains_dir}/#{domain_name}/bin/condalist.sh" do
  source "condalist.sh.erb"
  owner node['glassfish']['user']
  group node['glassfish']['group']
  mode 0750
  action :create
end



bash 'enable_sso' do
  user "root"
  code <<-EOF
      sleep 10
      curl --data "email=admin@kth.se&password=admin&otp=" http://localhost:8080/hopsworks-api/api/auth/login/
      curl --insecure --user #{username}:#{password} -s https://localhost:4848/asadmin
    EOF
end



bash "pip_upgrade" do
    user "root"
    code <<-EOF
      set -e
      pip install --upgrade pip
    EOF
end

scala_home=
case node['platform']
 when 'debian', 'ubuntu'
   scala_home="/usr/share/scala-2.11"
   package "scala" do
   end
 when 'redhat', 'centos', 'fedora'

  bash 'scala-install-redhat' do
    user "root"
    code <<-EOF
       cd #{Chef::Config['file_cache_path']}
       wget http://downloads.lightbend.com/scala/2.11.8/scala-2.11.8.rpm
       sudo yum install scala-2.11.8.rpm
       rm scala-2.11.8.rpm
    EOF
    not_if "which scala"
  end


  scala_home="/usr/share/scala-2.11"
end


#
# https://github.com/jupyter-incubator/sparkmagic
#
bash "jupyter-sparkmagic" do
  user 'root'
    retries 1
    code <<-EOF
    set -e
    pip install --upgrade urllib3
    pip install --upgrade requests
    pip install --upgrade jupyter
    pip install --upgrade sparkmagic
EOF
end


bash "pydoop" do
    user 'root'
    retries 1
    environment ({'JAVA_HOME' => node['java']['java_home'],
                 'HADOOP_HOME' => node['hops']['base_dir']})
    code <<-EOF
      set -e
      pip install --no-cache-dir hdfscontents
    EOF
    not_if "python -c 'import pydoop'"
end



bash "jupyter-sparkmagic-enable" do
    user "root"
    code <<-EOF
    jupyter nbextension enable --py --sys-prefix widgetsnbextension
EOF
end


if node['hopsworks']['pixiedust']['enabled'].to_str.eql?("true")
  cloudant="cloudant-spark-v2.0.0-185.jar"
  # Pixiedust is a visualization library for Jupyter
  pixiedust_home="#{node['jupyter']['base_dir']}/pixiedust"
  bash "jupyter-pixiedust" do
    user node['jupyter']['user']
    retries 1
    ignore_failure true
    code <<-EOF
      set -e
      mkdir -p #{pixiedust_home}/bin
      cd #{pixiedust_home}/bin
      export PIXIEDUST_HOME=#{pixiedust_home}
      export SPARK_HOME=#{node['hadoop_spark']['base_dir']}
      export SCALA_HOME=#{scala_home}
      pip --no-cache-dir install matplotlib
      pip --no-cache-dir install pixiedust
      jupyter pixiedust install --silent
      wget https://github.com/cloudant-labs/spark-cloudant/releases/download/v2.0.0/#{cloudant}
#      chown #{node['jupyter']['user']} -R #{pixiedust_home}
# pythonwithpixiedustspark22 - install in /usr/local/share/jupyter/kernels
      if [ -d /home/#{node['hopsworks']['user']}/.local/share/jupyter/kernels ] ; then
         jupyter-kernelspec install /home/#{node['jupyter']['user']}/.local/share/jupyter/kernels/pythonwithpixiedustspark2[0-9]
      fi
    EOF
    not_if "test -f #{pixiedust_home}/bin/#{cloudant}"
  end

end

pythondir=""
case node['platform']
 when 'debian', 'ubuntu'
  pythondir="/usr/local/lib/python2.7/dist-packages"
 when 'redhat', 'centos', 'fedora'
  pythondir="/usr/lib/python2.7/site-packages"
end

bash "jupyter-kernels" do
  user "root"
  code <<-EOF
    set -e
    cd #{pythondir}
    export HADOOP_HOME=#{node['hops']['base_dir']}
    jupyter-kernelspec install sparkmagic/kernels/sparkkernel
    jupyter-kernelspec install sparkmagic/kernels/pysparkkernel
    jupyter-kernelspec install sparkmagic/kernels/pyspark3kernel
    jupyter-kernelspec install sparkmagic/kernels/sparkrkernel
   EOF
end


#
# (Optional) Enable the server extension so that clusters can be programatically changed
#

case node['platform']
when 'debian', 'ubuntu'

  bash "jupyter-sparkmagic-kernel" do
    user "root"
    code <<-EOF
    set -e
    cd #{pythondir}
    # workaround for https://github.com/ipython/ipython/issues/9656
    pip uninstall -y backports.shutil_get_terminal_size
    pip install --upgrade backports.shutil_get_terminal_size
    export HADOOP_HOME=#{node['hops']['base_dir']}
    jupyter serverextension enable --py sparkmagic
   EOF
  end
when 'redhat', 'centos', 'fedora'

  bash "jupyter-sparkmagic-kernel" do
    user "root"
    code <<-EOF
    set -e
    # workaround for https://github.com/ipython/ipython/issues/9656
    pip uninstall -y backports.shutil_get_terminal_size
    pip install --upgrade backports.shutil_get_terminal_size
    # https://github.com/conda/conda/issues/4823
    pip install 'configparser===3.5.0b2'
    export HADOOP_HOME=#{node['hops']['base_dir']}
    jupyter serverextension enable --py sparkmagic
   EOF
  end

end


homedir = "/home/#{node['hopsworks']['user']}"


# directory "#{homedir}/.sparkmagic"  do
#   owner node['hopsworks']['user']
#   group node['hopsworks']['group']
#   mode "755"
#   action :create
# end


# template "#{homedir}/.sparkmagic/config.json" do
#   source "config.json.erb"
#   owner node['hopsworks']['user']
#   mode 0750
#   action :create
#   variables({
#               :livy_ip => livy_ip,
#                :homedir => homedir
#   })
# end

#
# Disable glassfish service, if node['services']['enabled'] is not set to true
#
if node['services']['enabled'] != "true"

  case node['platform']
  when "ubuntu"
    if node['platform_version'].to_f <= 14.04
      node.override['hopsworks']['systemd'] = "false"
    end
  end

  if node['hopsworks']['systemd'] == "true"

    service "glassfish-domain1" do
      provider Chef::Provider::Service::Systemd
      supports :restart => true, :stop => true, :start => true, :status => true
      action :disable
    end

  else #sysv

    service "glassfish-domain1" do
      provider Chef::Provider::Service::Init::Debian
      supports :restart => true, :stop => true, :start => true, :status => true
      action :disable
    end
  end

end


directory node['hopsworks']['staging_dir']  do
  owner node['hopsworks']['user']
  group node['hopsworks']['group']
  mode "775"
  action :create
  recursive true
end

directory node['hopsworks']['staging_dir'] + "/private_dirs"  do
  owner node['jupyter']['user']
  group node['hopsworks']['group']
  mode "0330"
  action :create
end



kagent_keys "#{homedir}" do
  cb_user node['hopsworks']['user']
  cb_group node['hopsworks']['group']
  action :generate
end

kagent_keys "#{homedir}" do
  cb_user node['hopsworks']['user']
  cb_group node['hopsworks']['group']
  cb_name "hopsworks"
  cb_recipe "default"
  action :return_publickey
end

hopsworks_grants "restart_glassfish" do
  action :reload_systemd
end


template "#{domains_dir}/#{domain_name}/bin/letsencrypt.sh" do
  source "letsencrypt.sh.erb"
  owner node['glassfish']['user']
  mode 0770
  action :create
end

template "#{domains_dir}/#{domain_name}/bin/convert-ipython-notebook.sh" do
  source "convert-ipython-notebook.sh.erb"
  owner node['glassfish']['user']
  mode 0750
  action :create
end

pythonDir="/usr/lib/python2.7/site-packages"
case node['platform']
 when 'debian', 'ubuntu'
   pythonDir="/usr/local/lib/python2.7/dist-packages"
 when 'redhat', 'centos', 'fedora'
   pythonDir="/usr/lib/python2.7/site-packages"
end


bash "jupyter-root-sparkmagic" do
  user 'root'
  code <<-EOF
    set -e
    source ~/.bashrc
    pip uninstall numpy -y
    pip install --target #{pythonDir} --upgrade numpy
    pip uninstall pbr -y
    pip install --target #{pythonDir} --upgrade pbr
    pip uninstall funcsigs -y
    pip install --target #{pythonDir} --upgrade funcsigs
    pip uninstall setuptools  -y
    pip install --target #{pythonDir} --upgrade setuptools
    pip uninstall mock  -y
    pip install --target #{pythonDir} --upgrade mock
    pip uninstall configparser  -y
    pip install --target #{pythonDir} --upgrade configparser
    pip uninstall sparkmagic  -y
    pip install --target #{pythonDir} --upgrade sparkmagic
   EOF
end

if vagrant_enabled == 1
  bash "fix_owner_ship_pip_files" do
    user 'root'
    code <<-EOF
    if [ -d /home/#{node['jupyter']['user']}/.local ] ; then
       chown -R #{node['jupyter']['user']} /home/#{node['jupyter']['user']}/.local
    fi
   EOF
  end
end


bash "jupyter-user-sparkmagic" do
  user 'root'
  code <<-EOF
    su -l #{node['jupyter']['user']} -c "pip install --upgrade --no-cache-dir --user sparkmagic"
   EOF
end

directory "/usr/local/share/jupyter/nbextensions/facets-dist"  do
  owner "root"
  group "root"
  mode "775"
  action :create
  recursive true
end

template "/usr/local/share/jupyter/nbextensions/facets-dist/facets-jupyter.html" do
  source "facets-jupyter.html.erb"
  owner "root"
  mode 0775
  action :create
end

directory "#{theDomain}/docroot/nbextensions/facets-dist" do
  owner node['glassfish']['user']
  group node['glassfish']['group']
  mode "775"
  action :create
  recursive true
end

template "#{theDomain}/docroot/nbextensions/facets-dist/facets-jupyter.html" do
  source "facets-jupyter.html.erb"
  owner node['glassfish']['user']
  group node['glassfish']['group']
  mode 0775
  action :create
end
