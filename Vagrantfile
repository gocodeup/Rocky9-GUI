# -*- mode: ruby -*- # vi: set ft=ruby :
Vagrant.configure("2") do |config|
    # Base VM OS configuration.
    config.ssh.insert_key = false
    config.vm.synced_folder '.', '/vagrant', disabled: true
    config.disksize.size = '80GB'
    # General VirtualBox VM configuration.
    config.vm.provider :virtualbox do |v|
      v.gui = true
      v.memory = 1024
      v.cpus = 1
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
    end
  
    # rocky.
    config.vm.define "rocky" do |rocky|
      rocky.vm.hostname = "Rocky9GUI"
      rocky.vm.network :private_network, ip: "192.168.2.100"
      config.vm.box = "cobra-cli/Rocky9GUI"
      config.ssh.insert_key = false
      rocky.vm.provider :virtualbox do |v|
        v.customize ["modifyvm", :id, "--audio", "none"]
        v.customize ["modifyvm", :id, "--memory", 16392]
        v.customize ["modifyvm", :id, "--cpus", 8]
        v.customize ["modifyvm", :id, "--vram", 128]
        v.customize ["modifyvm", :id, "--accelerate3d", "off"]
      end
    config.vm.synced_folder ".", "/vagrant", type: "rsync",
      rsync__exclude: ".git/"
    config.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "playbook.yml"
    end
    end
  end
