#! /bin/bash

apt_install_prerequisites() {
  # Install prerequisites and useful tools
  apt-get update
  apt-get install -y jq whois build-essential git docker docker-compose unzip mongodb-org
}

fix_eth1_static_ip() {
  # There's a fun issue where dhclient keeps messing with eth1 despite the fact
  # that eth1 has a static IP set. We workaround this by setting a static DHCP lease.
  echo -e 'interface "eth1" {
    send host-name = gethostname();
    send dhcp-requested-address 192.168.38.105;
  }' >> /etc/dhcp/dhclient.conf
  service networking restart
  # Fix eth1 if the IP isn't set correctly
  ETH1_IP=$(ifconfig eth1 | grep 'inet addr' | cut -d ':' -f 2 | cut -d ' ' -f 1)
  if [ "$ETH1_IP" != "192.168.38.105" ]; then
    echo "Incorrect IP Address settings detected. Attempting to fix."
    ifdown eth1
    ip addr flush dev eth1
    ifup eth1
    ETH1_IP=$(ifconfig eth1 | grep 'inet addr' | cut -d ':' -f 2 | cut -d ' ' -f 1)
    if [ "$ETH1_IP" == "192.168.38.105" ]; theng
      echo "The static IP has been fixed and set to 192.168.38.105"
    else
      echo "Failed to fix the broken static IP for eth1. Exiting because this will cause problems with other VMs."
      exit 1
    fi
  fi
}

install_python() {
  # Install Python 3.6.4
  if ! which /usr/local/bin/python3.6 > /dev/null; then
    echo "Installing Python v3.6.4..."
    wget https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tgz
    tar -xvf Python-3.6.4.tgz
    cd Python-3.6.4 || exit
    ./configure && make && make install
    cd /home/vagrant || exit
  else
    echo "Python seems to be downloaded already.. Skipping."
  fi
}

install_splunk() {
  # Check if Splunk is already installed
  if [ -f "/opt/splunk/bin/splunk" ]; then
    echo "Splunk is already installed"
  else
    echo "Installing Splunk..."
    # Get Splunk.com into the DNS cache. Sometimes resolution randomly fails during wget below
    dig @8.8.8.8 splunk.com
    # Download Splunk
    wget --progress=bar:force -O splunk-7.2.1-be11b2c46e23-linux-2.6-amd64.deb 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.2.1&product=splunk&filename=splunk-7.2.1-be11b2c46e23-linux-2.6-amd64.deb&wget=true'
    dpkg -i splunk-7.2.1-be11b2c46e23-linux-2.6-amd64.deb
    
    /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd changeme

	/opt/splunk/bin/splunk install app /vagrant/resources/fortinet-fortigate-add-on-for-splunk_160.tgz  -auth 'admin:changeme'
	/opt/splunk/bin/splunk install app /vagrant/resources/splunk-add-on-for-tenable_514.tgz  -auth 'admin:changeme'
	/opt/splunk/bin/splunk install app /vagrant/resources/splunk-stream_712.tgz  -auth 'admin:changeme'	
    /opt/splunk/bin/splunk install app /vagrant/resources/splunk-add-on-for-microsoft-windows_500.tgz -auth 'admin:changeme'
	/opt/splunk/bin/splunk install app /vagrant/resources/splunk-ta-for-suricata_233.tgz  -auth 'admin:changeme'    
    /opt/splunk/bin/splunk install app /vagrant/resources/add-on-for-microsoft-sysmon_800.tgz -auth 'admin:changeme'
	/opt/splunk/bin/splunk install app /vagrant/resources/url-toolbox_16.tgz  -auth 'admin:changeme'
	/opt/splunk/bin/splunk install app /vagrant/resources/botsv1_data_set.tgz  -auth 'admin:changeme'


    # Add props.conf and transforms.conf
    cp /vagrant/resources/props.conf /opt/splunk/etc/apps/search/local/
    cp /vagrant/resources/transforms.conf /opt/splunk/etc/apps/search/local/
    cp /opt/splunk/etc/system/default/limits.conf /opt/splunk/etc/system/local/limits.conf
    # Bump the memtable limits to allow for the ASN lookup table
    sed -i.bak 's/max_memtable_bytes = 10000000/max_memtable_bytes = 30000000/g' /opt/splunk/etc/system/local/limits.conf

    # Skip Splunk Tour and Change Password Dialog
    touch /opt/splunk/etc/.ui_login
    # Enable SSL Login for Splunk
    echo '[settings]
    enableSplunkWebSSL = true' > /opt/splunk/etc/system/local/web.conf
    
    # Reboot Splunk to make changes take effect
    /opt/splunk/bin/splunk restart
    /opt/splunk/bin/splunk enable boot-start
    
  fi
}

main() {
  apt_install_prerequisites
  fix_eth1_static_ip
  #install_python
  install_splunk
}

main
exit 0
