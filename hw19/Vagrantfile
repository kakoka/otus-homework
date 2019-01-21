# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
:Router1 => {
      :box_name => "centos/7",
      :net => [
                  {adapter: 2, auto_config: false, virtualbox__intnet: "area0"},
                  {ip: '10.10.1.1', adapter: 3, netmask: "255.255.255.0", virtualbox__intnet: "area1"}
              ]
  },
  :Router2 => {
    :box_name => "centos/7",
    :net => [
                {adapter: 2, auto_config: false, virtualbox__intnet: "area0"},
                {ip: '10.10.2.1', adapter: 3, netmask: "255.255.255.0", virtualbox__intnet: "area2"}
            ]
},
  :Router3 => {
      :box_name => "centos/7",
      :net => [
                  {adapter: 2, auto_config: false, virtualbox__intnet: "area0"},
                  {ip: '10.10.3.1', adapter: 3, netmask: "255.255.255.0", virtualbox__intnet: "area3"}
              ]
  },
  :Client1 => {
    :box_name => "centos/7",
    :net => [
                  {adapter: 2, auto_config: false, virtualbox__intnet: "area1"}
            ]
},
  :Client3 => {
    :box_name => "centos/7",
    :net => [
                  {adapter: 2, auto_config: false, virtualbox__intnet: "area3"}
            ]
}
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

    config.vm.define boxname do |box|

        box.vm.box = boxconfig[:box_name]
        box.vm.host_name = boxname.to_s

        config.vm.provider "virtualbox" do |v|
          v.memory = 256
        end

        boxconfig[:net].each do |ipconf|
          box.vm.network "private_network", ipconf
        end
        
        if boxconfig.key?(:public)
          box.vm.network "public_network", boxconfig[:public]
        end
        box.vm.provision "ansible" do |ansible|
          ansible.become = true
          ansible.verbose = "v"
          ansible.playbook = "add_local_user.yml"
        end        
        box.vm.provision "shell", inline: <<-SHELL
          mkdir -p ~root/.ssh
                cp ~vagrant/.ssh/auth* ~root/.ssh
        SHELL


        
        case boxname.to_s
          when "Router1"
            box.vm.provision "shell", run: "always", inline: <<-SHELL
              echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
              echo net.ipv4.conf.all.forwarding=1  >> /etc/sysctl.conf
              echo net.ipv4.conf.all.rp_filter=0 >> /etc/sysctl.conf
              sysctl -p /etc/sysctl.conf
              yum -y install quagga tcpdump
              echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
              echo -e "NM_CONTROLED=no\nBOOTPROTO=static\nVLAN=yes\nONBOOT=yes\nIPADDR=192.168.10.1\nPREFIX=30\nDEVICE=eth1.1" > /etc/sysconfig/network-scripts/ifcfg-eth1.1
              echo -e "NM_CONTROLED=no\nBOOTPROTO=static\nVLAN=yes\nONBOOT=yes\nIPADDR=192.168.10.10\nPREFIX=30\nDEVICE=eth1.3" > /etc/sysconfig/network-scripts/ifcfg-eth1.3
              systemctl restart network
              cp /vagrant/router1/zebra.conf /etc/quagga/zebra.conf
              cp /vagrant/router1/ospfd.conf /etc/quagga/ospfd.conf
              cp /vagrant/etc/hosts /etc/hosts
              cp /vagrant/etc/daemons /etc/daemons
              chown quagga:quaggavt /etc/quagga/ospfd.conf && chown quagga:quagga /etc/quagga/zebra.conf
              systemctl enable zebra ospfd && systemctl start zebra ospfd
              setsebool -P zebra_write_config 1
              SHELL
            # box.vm.provision "ansible" do |ansible|
            #   ansible.become = true
            #   ansible.verbose = "v"
            #   ansible.playbook = "network-nmcli.yml"
            # end
          when "Router2"
            box.vm.provision "shell", run: "always", inline: <<-SHELL
              echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
              echo net.ipv4.conf.all.forwarding=1  >> /etc/sysctl.conf
              echo net.ipv4.conf.all.rp_filter=0 >> /etc/sysctl.conf
              sysctl -p /etc/sysctl.conf
              yum -y install quagga tcpdump
              echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
              echo -e "NM_CONTROLED=no\nBOOTPROTO=static\nVLAN=yes\nONBOOT=yes\nIPADDR=192.168.10.2\nPREFIX=30\nDEVICE=eth1.1" > /etc/sysconfig/network-scripts/ifcfg-eth1.1
              echo -e "NM_CONTROLED=no\nBOOTPROTO=static\nVLAN=yes\nONBOOT=yes\nIPADDR=192.168.10.5\nPREFIX=30\nDEVICE=eth1.2" > /etc/sysconfig/network-scripts/ifcfg-eth1.2
              systemctl restart network
              cp /vagrant/router2/zebra.conf /etc/quagga/zebra.conf
              cp /vagrant/router2/ospfd.conf /etc/quagga/ospfd.conf
              cp /vagrant/etc/hosts /etc/hosts
              cp /vagrant/etc/daemons /etc/daemons
              chown quagga:quaggavt /etc/quagga/ospfd.conf && chown quagga:quagga /etc/quagga/zebra.conf
              systemctl enable zebra ospfd && systemctl start zebra ospfd
              setsebool -P zebra_write_config 1
              SHELL
            # box.vm.provision "ansible" do |ansible|
            #   ansible.become = true
            #   ansible.verbose = "v"
            #   ansible.playbook = "network-nmcli.yml"
            # end
          when "Router3"
            box.vm.provision "shell", run: "always", inline: <<-SHELL
              echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
              echo net.ipv4.conf.all.forwarding=1  >> /etc/sysctl.conf
              echo net.ipv4.conf.all.rp_filter=0 >> /etc/sysctl.conf
              sysctl -p /etc/sysctl.conf
              yum -y install quagga tcpdump
              echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
              echo -e "NM_CONTROLED=no\nBOOTPROTO=static\nVLAN=yes\nONBOOT=yes\nIPADDR=192.168.10.6\nPREFIX=30\nDEVICE=eth1.2" > /etc/sysconfig/network-scripts/ifcfg-eth1.2
              echo -e "NM_CONTROLED=no\nBOOTPROTO=static\nVLAN=yes\nONBOOT=yes\nIPADDR=192.168.10.9\nPREFIX=30\nDEVICE=eth1.3" > /etc/sysconfig/network-scripts/ifcfg-eth1.3
              systemctl restart network
              cp /vagrant/router3/zebra.conf /etc/quagga/zebra.conf
              cp /vagrant/router3/ospfd.conf /etc/quagga/ospfd.conf
              cp /vagrant/etc/hosts /etc/hosts
              cp /vagrant/etc/daemons /etc/daemons
              chown quagga:quaggavt /etc/quagga/ospfd.conf && chown quagga:quagga /etc/quagga/zebra.conf
              systemctl enable zebra ospfd && systemctl start zebra ospfd
              setsebool -P zebra_write_config 1
              SHELL
            # box.vm.provision "ansible" do |ansible|
            #   ansible.become = true
            #   ansible.verbose = "v"
            #   ansible.playbook = "network-nmcli.yml"
            # end
          when "Client1"
            box.vm.provision "shell", run: "always", inline: <<-SHELL
            echo net.ipv4.conf.all.rp_filter=0 >> /etc/sysctl.conf
            sysctl -p /etc/sysctl.conf
            yum install traceroute tcpdump wireshark -y
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
            echo -e "NM_CONTROLED=no\nBOOTPROTO=static\nVLAN=yes\nONBOOT=yes\nIPADDR=10.10.1.2\nPREFIX=24\nGATEWAY=10.10.1.1\nDEVICE=eth1" > /etc/sysconfig/network-scripts/ifcfg-eth1
            sudo systemctl restart network
            cp /vagrant/etc/hosts /etc/hosts
            SHELL
          when "Client3"
            box.vm.provision "shell", run: "always", inline: <<-SHELL
            echo net.ipv4.conf.all.rp_filter=0 >> /etc/sysctl.conf
            sysctl -p /etc/sysctl.conf
            yum install traceroute tcpdump wireshark -y
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
            echo -e "NM_CONTROLED=no\nBOOTPROTO=static\nVLAN=yes\nONBOOT=yes\nIPADDR=10.10.3.2\nPREFIX=24\nGATEWAY=10.10.3.1\nDEVICE=eth1" > /etc/sysconfig/network-scripts/ifcfg-eth1
            sudo systemctl restart network
            cp /vagrant/etc/hosts /etc/hosts
            SHELL
          end
      end

  end
  
  
end
