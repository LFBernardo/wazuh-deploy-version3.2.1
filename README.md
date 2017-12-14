# wazuh-deploy

 NOTE: Elastic is in the process of updating packages. Some of the installs will fail until they are complete. 14/12/2017

Automation script for single host Wazuh deployment. (Debian/Ubuntu based)
This script was created to simplify the deployment of Wazuh in mass testing exercises. I take no responsibility for the consequences of running this script, it works for me :)

Tested on Ubuntu Server 16.04.3 LTS December 2017

If you receive errors similar to the following:
"cannot copy extracted data for './etc/init.d/kibana' to '/etc/init.d/kibana.dpkg-new': unexpected end of file or stream"
your download was probably interupted or corrupt. Perform apt-get clean, apt-get update and reinstall the offending package. Remeber to re-enable the elastic repository by uncommenting  "deb https://artifacts.elastic.co/packages/6.x/apt stable main" in /etc/apt/sources.list.d/elastic-6.x.list. If the error persists follow normal apt and dpkg troubleshooting steps.
 

