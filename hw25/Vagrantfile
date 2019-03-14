# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vm.provision "ansible" do |ansible|
    # ansible.groups = {
    #   "dns" => ["dns"],
    #   "nodes" => ["node01","node02","node03"]
    #   }
    ansible.verbose = "v"
    ansible.playbook = "provisioning/playbook.yml"
    ansible.sudo = "true"
  end
  config.vm.provider "virtualbox" do |v|
          v.memory = 1024
  end
  config.vm.define "master" do |master|
    master.vm.network "private_network", ip: "192.168.50.100", virtualbox__intnet: "private"
    master.vm.hostname = "master"
  end
  config.vm.define "slave" do |slave|
    slave.vm.network "private_network", ip: "192.168.50.101", virtualbox__intnet: "private"
    slave.vm.hostname = "slave"
  end
end
