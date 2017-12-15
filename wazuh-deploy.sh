#/bin/bash


# This script will deploy Wazuh and it's dependencies on a single host.
# abbreviated version of commands from the URL in the next line. Some added sed instructions to perform configuration.
# URL1: https://documentation.wazuh.com/current/installation-guide/installing-wazuh-server/wazuh_server_deb.html#wazuh-server-deb
# URL2: https://documentation.wazuh.com/current/installation-guide/installing-elastic-stack/elastic_server_deb.html#elastic-server-deb
# I make no claims of ownership nor do I take any responsibility for the consequences of running this script. 


#preparation
set -x #for debug
apt-get update
apt-get install curl apt-transport-https lsb-release -y

#add repo and key
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
echo "deb https://packages.wazuh.com/3.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt-get update

#Install Wazuh Manager
apt-get install wazuh-manager -y
systemctl status wazuh-manager
service wazuh-manager status
sleep 5

#Adding Wazuh API
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
apt-get install nodejs -y
apt-get install wazuh-api -y
systemctl status wazuh-api
service wazuh-api status
sleep 5

############################################################################################################################
#Add filebeat
####################### Uncomment the following bbefore running if you need filebeat locally ###############################
#curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
#echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-6.x.list
#apt-get update
#apt-get install filebeat -y
#curl -so /etc/filebeat/filebeat.yml https://raw.githubusercontent.com/wazuh/wazuh/3.0/extensions/filebeat/filebeat.yml
#sed -i 's/ELASTIC_SERVER_IP/127.0.0.1/g' /etc/filebeat/filebeat.yml
#systemctl daemon-reload
#systemctl enable filebeat.service
#systemctl start filebeat.service
#systemctl status filebeat.service
#sleep 5
############################################################################################################################

#Install ELK
#Java
echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list
echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
add-apt-repository ppa:webupd8team/java -y
apt-get update
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
apt-get install oracle-java8-installer -y
curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-6.x.list
apt-get update
#Elasticsearch
apt-get install elasticsearch=6.1.0 -y
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service
#add Wazuh templates
curl https://raw.githubusercontent.com/wazuh/wazuh/3.0/extensions/elasticsearch/wazuh-elastic6-template-alerts.json | curl -XPUT 'http://localhost:9200/_template/wazuh' -H 'Content-Type: application/json' -d @-
sleep 6
curl https://raw.githubusercontent.com/wazuh/wazuh/3.0/extensions/elasticsearch/wazuh-elastic6-template-monitoring.json | curl -XPUT 'http://localhost:9200/_template/wazuh-agent' -H 'Content-Type: application/json' -d @-
sleep 6
curl https://raw.githubusercontent.com/wazuh/wazuh/3.0/extensions/elasticsearch/alert_sample.json | curl -XPUT "http://localhost:9200/wazuh-alerts-3.x-"`date +%Y.%m.%d`"/wazuh/sample" -H 'Content-Type: application/json' -d @-
sleep 6
#Logstash
apt-get install logstash=6.1.0 -y
curl -so /etc/logstash/conf.d/01-wazuh.conf https://raw.githubusercontent.com/wazuh/wazuh/3.0/extensions/logstash/01-wazuh-local.conf
usermod -a -G ossec logstash
systemctl daemon-reload
systemctl enable logstash.service
systemctl start logstash.service
sleep 5

#Kibana
apt-get install kibana=6.1.0 -y
#The commented line below appears to be problematic with proxy servers and or dodgy internet connections. The new lines compensate for this.
#/usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp.zip
wget https://packages.wazuh.com/wazuhapp/wazuhapp.zip -O /tmp/wazuhapp.zip
/usr/share/kibana/bin/kibana-plugin install file:///tmp/wazuhapp.zip

sed -i '/#server.host: "localhost"/c\server.host: "0.0.0.0"' /etc/kibana/kibana.yml
systemctl daemon-reload
systemctl enable kibana.service
systemctl start kibana.service
sleep 5

#disable elastic repo to prevent unintentional damage when new versions are released
sed -i -r '/deb https:\/\/artifacts.elastic.co\/packages\/6.x\/apt stable main/ s/^(.*)$/#\1/g' /etc/apt/sources.list.d/elastic-6.x.list
