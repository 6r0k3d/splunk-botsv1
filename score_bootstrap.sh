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
    send dhcp-requested-address 192.168.38.106;
  }' >> /etc/dhcp/dhclient.conf
  service networking restart
  # Fix eth1 if the IP isn't set correctly
  ETH1_IP=$(ifconfig eth1 | grep 'inet addr' | cut -d ':' -f 2 | cut -d ' ' -f 1)
  if [ "$ETH1_IP" != "192.168.38.106" ]; then
    echo "Incorrect IP Address settings detected. Attempting to fix."
    ifdown eth1
    ip addr flush dev eth1
    ifup eth1
    ETH1_IP=$(ifconfig eth1 | grep 'inet addr' | cut -d ':' -f 2 | cut -d ' ' -f 1)
    if [ "$ETH1_IP" == "192.168.38.106" ]; then
      echo "The static IP has been fixed and set to 192.168.38.106"
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
	echo
  fi
    echo "Installing Splunk..."
    # Get Splunk.com into the DNS cache. Sometimes resolution randomly fails during wget below
    dig @8.8.8.8 splunk.com
    # Download Splunk
    wget --progress=bar:force -O splunk-7.2.1-be11b2c46e23-linux-2.6-amd64.deb 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.2.1&product=splunk&filename=splunk-7.2.1-be11b2c46e23-linux-2.6-amd64.deb&wget=true'
    dpkg -i splunk-7.2.1-be11b2c46e23-linux-2.6-amd64.deb
    
    /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd changeme

	/opt/splunk/bin/splunk install app /vagrant/resources/lookup-file-editor_321.tgz -auth 'admin:changeme'
    /opt/splunk/bin/splunk install app /vagrant/resources/parallel-coordinates-custom-visualization_130.tgz -auth 'admin:changeme'
    /opt/splunk/bin/splunk install app /vagrant/resources/simple-timeseries-custom-visualization_10.tgz -auth 'admin:changeme'
    /opt/splunk/bin/splunk install app /vagrant/resources/timeline-custom-visualization_130.tgz -auth 'admin:changeme'
    

	git clone https://github.com/splunk/SA-ctf_scoreboard
	mv SA-ctf_scoreboard /opt/splunk/etc/apps

	git clone https://github.com/splunk/SA-ctf_scoreboard_admin 
	mv SA-ctf_scoreboard_admin /opt/splunk/etc/apps
	
    # Reboot Splunk to make changes take effect
    /opt/splunk/bin/splunk restart
    /opt/splunk/bin/splunk enable boot-start
	

	mkdir /opt/splunk/var/log/scoreboard	

	/opt/splunk/bin/splunk add user cabanaboy -password 'changeme' -role ctf_answers_service -auth "admin:changeme"
	/opt/splunk/bin/splunk add user ctfadmin -password 'changeme' -role admin -role ctf_admin -role can_delete -auth "admin:changeme"
	
	cat << EOF > /opt/splunk/etc/apps/SA-ctf_scoreboard/appserver/controllers/scoreboard_controller.config
[ScoreboardController]
USER = cabanaboy
PASS = changeme
VKEY = abcdef1234567890
EOF

    # Reboot Splunk to make changes take effect
    /opt/splunk/bin/splunk restart
    
    # Skip Splunk Tour and Change Password Dialog
    touch /opt/splunk/etc/.ui_login
    # Enable SSL Login for Splunk
    echo '[settings]
    enableSplunkWebSSL = true' > /opt/splunk/etc/system/local/web.conf


	


  #fi
}

main() {
  apt_install_prerequisites
  fix_eth1_static_ip
  install_python
  install_splunk
}

main
exit 0
