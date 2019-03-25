Vagrant.configure("2") do |config|

  config.vm.define "bots" do |cfg|
    cfg.vm.box = "bento/ubuntu-16.04"
    cfg.vm.hostname = "bots"
    config.vm.provision :shell, path: "bots_bootstrap.sh"
    cfg.vm.network :private_network, ip: "192.168.38.105", gateway: "192.168.38.1", dns: "8.8.8.8"

    cfg.vm.provider "virtualbox" do |vb, override|
      vb.gui = true
      vb.name = "bots"
      vb.customize ["modifyvm", :id, "--memory", 4096]
      vb.customize ["modifyvm", :id, "--cpus", 2]
      vb.customize ["modifyvm", :id, "--vram", "32"]
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["setextradata", "global", "GUI/SuppressMessages", "all" ]
    end
  end
  
  config.vm.define "scoreboard" do |cfg|
    cfg.vm.box = "bento/ubuntu-16.04"
    cfg.vm.hostname = "scoreboard"
    config.vm.provision :shell, path: "score_bootstrap.sh"
    cfg.vm.network :private_network, ip: "192.168.38.106", gateway: "192.168.38.1", dns: "8.8.8.8"

    cfg.vm.provider "virtualbox" do |vb, override|
      vb.gui = true
      vb.name = "scoreboard"
      vb.customize ["modifyvm", :id, "--memory", 4096]
      vb.customize ["modifyvm", :id, "--cpus", 2]
      vb.customize ["modifyvm", :id, "--vram", "32"]
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["setextradata", "global", "GUI/SuppressMessages", "all" ]
    end
  end
end
