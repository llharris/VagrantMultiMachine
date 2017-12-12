# -*- mode: ruby -*-
# vi: set ft=ruby :
# Include slightly modified version of plugin by Exratione: https://github.com/exratione/vagrant-provision-reboot
require './include/vagrant-provision-reboot-plugin'

#################################################
########## USER CUSTOMISABLE VARIABLES ##########
#################################################

# Private Network Range, first three octets (Assumes /24 network)
#################################################################
$network = "192.168.35"

# Master
########
$master_cpu = 2
$master_ram = 4096

# Linux Nodes
#############
$linode_count = 1 # Don't exceed 89 linodes if deploying both Linux & Windows
$linode_cpu = 1
$linode_ram = 1024
$linode_box_image = "centos/7"

# Windows Nodes
###############
$winode_count = 1 # winode_count must not exceed 154 or you'll get nonsensical IP addresses
$winode_cpu = 1
$winode_ram = 2048
$winode_box_image = "derekgroh/windows-2012r2-amd64-sysprep"
$language = "en-GB" # Use to set Windows language, default is en-US. Must be valid input to the Set-WinUserLanguageList PowerShell cmdlet.

# Windows AD Control
####################
$enable_ad = true
$dc_cpu = 2
$dc_ram = 4096
$domain_name = "testlab.local"
$domain_netbios_name = "testlab"
$safe_mode_admin_password = "Pa55w0rd!"
$win_clients_join_domain = true

# Environment Control
#####################
# Uncomment environment type as required. Only one at a time of course ;)
$env_type = "ansible" 
#$env_type = "chef"
#$env_type = "salt"

#################################################
########## NO EDITS BELOW THIS LINE #############
#################################################

#################################################
########## SHELL PROVISIONER SCRIPTS ############
#################################################

$linux_base_config = <<SCRIPT
localectl set-keymap uk
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd
yum install screen mlocate zip unzip epel-release bind-utils net-tools git policycoreutils-python libsemanage-python tcpdump wget -y
curl https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant > /home/vagrant/.ssh/id_rsa
curl https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub > /home/vagrant/.ssh/id_rsa.pub
cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 0600 /home/vagrant/.ssh/id_rsa
systemctl enable chronyd
systemctl restart chronyd
SCRIPT

$linux_dnsmasq = <<SCRIPT
yum install dnsmasq -y
cat >/etc/dnsmasq.conf <<EOL
bogus-priv
no-resolv
server=8.8.8.8
server=8.8.4.4
local=/#{$domain_name}/
expand-hosts
domain=#{$domain_name}
EOL
cat >/etc/hosts <<EOL
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
#{$network}.9  windc
#{$network}.10 master
EOL
if [[ "#{$linode_count}" -gt 0 ]]; then
    for l in {1..#{$linode_count}}; do
        (( last_octet = $l+10 ))
        echo "#{$network}.${last_octet} linux${l} linux${l}.#{$domain_name}" >> /etc/hosts
    done
fi
if [[ "#{$winode_count}" -gt 0 ]]; then
    for w in {1..#{$winode_count}}; do
        (( last_octet = $w+100 ))
        echo "#{$network}.${last_octet} win${w} win${w}.#{$domain_name}" >> /etc/hosts
    done
fi
systemctl enable dnsmasq
systemctl restart dnsmasq
SCRIPT

$linux_config_dnsclient = <<SCRIPT
if [[ "#{$enable_ad}" == "true" ]]; then
    dns_server_ip="#{$network}.9"
else
    dns_server_ip="#{$network}.10"
fi
echo "PEERDNS=\"no\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "DNS1=\"$dns_server_ip\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "DOMAIN=\"#{$domain_name}\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0
systemctl restart NetworkManager
SCRIPT

$master_install_cm = <<SCRIPT
echo "Installing Master Server ConfigMgmt Tools: #{$env_type}..."
if [[ "#{$env_type}" == "ansible" ]]; then
    yum install ansible-2.4.1.0-1.el7.noarch ansible-doc-2.4.1.0-1.el7.noarch -y
    useradd -G vagrant -s /bin/bash -d /home/ansible -m ansible
    echo "ansible" | passwd --stdin ansible
    mkdir /home/ansible/.ssh
    ssh-keygen -b 2048 -t rsa -f /home/ansible/.ssh/id_rsa -q -N "" -C ansible
    cp /home/ansible/.ssh/id_rsa.pub /home/ansible/.ssh/authorized_keys
    chown ansible:ansible -R /home/ansible/.ssh
    chmod 0700 /home/ansible/.ssh
    chmod 0600 /home/ansible/.ssh/*
fi
if [[ "#{$env_type}" == "chef" ]]; then
    firewalld_status_rc=$(systemctl status firewalld >/dev/null 2>&1;echo $?)
    if [[ "$firewalld_status_rc" -eq 0 ]]; then
        firewall-cmd --zone=public --add-service=http --permanent
        firewall-cmd --zone=public --add-service=https --permanent
        firewall-cmd --reload
    fi
    wget -O /tmp/chef-server-core-12.17.5-1.el7.x86_64.rpm https://packages.chef.io/files/stable/chef-server/12.17.5/el/7/chef-server-core-12.17.5-1.el7.x86_64.rpm
    yum localinstall /tmp/chef-server-core-12.17.5-1.el7.x86_64.rpm -y
    chef-server-ctl reconfigure
    chef-server-ctl user-create chef Chef User chef@testlab.local 'chef123' --filename /root/chef.pem
    chef-server-ctl org-create testlab testlab --association_user chef --filename /root/chef.pem
fi
if [[ "#{$env_type}" == "salt" ]]; then
    yum install https://repo.saltstack.com/yum/redhat/salt-repo-latest-2.el7.noarch.rpm -y
    yum clean expire-cache
    yum install salt-master salt-minion salt-ssh salt-api -y
    for i in salt-master salt-minion salt-api; do
        systemctl enable $i
        systemctl start $i
    done
fi
SCRIPT

$linked_clone = true

Vagrant.configure("2") do |config|
    config.winrm.transport = :plaintext
    config.winrm.basic_auth_only = true
    config.vm.synced_folder '.', '/vagrant', disabled: true

    if $enable_ad == true
        config.vm.define "dc" do |dc|
            dc.vm.box = $winode_box_image
            dc.vm.hostname = "windc"
            dc.vm.communicator = "winrm"
            dc.vm.provision :shell do |adds|
                adds.path = "scripts/configure_dc.ps1"
                adds.args = "#{$domain_name} #{$domain_netbios_name} #{$safe_mode_admin_password} #{$network} #{$linode_count} #{$winode_count} #{$language}"
                end
            dc.vm.network :private_network, ip: "#{$network}.9"
            dc.vm.network :forwarded_port, 
                host: 9389,
                guest: 3389,
                id: "rdp",
                auto_correct: true            
            dc.vm.provider "virtualbox" do |vb|
                vb.memory = $dc_ram
                vb.cpus = $dc_cpu
                vb.linked_clone = $linked_clone
            end
        end
    end

    config.vm.define "master" do |master|
        master.vm.box = "centos/7"
        master.vm.hostname = "master"
        master.vm.network :private_network, ip: "#{$network}.10"
        master.vm.provider "virtualbox" do |vb|
            vb.memory = $master_ram
            vb.cpus = $master_cpu
            vb.linked_clone = $linked_clone
        end
        master.vm.provision "shell", inline: <<-SHELL
        #{$linux_base_config}
        SHELL
        if $enable_ad == false # We only install and configure DNSmasq if AD isn't being used. Sacking off AD shite.
            master.vm.provision "shell", inline: <<-SHELL
            #{$linux_dnsmasq} 
            SHELL
        end
        master.vm.provision "shell", inline: <<-SHELL
        #{$linux_config_dnsclient}
        #{$master_install_cm}
        SHELL
    end

    (1..$linode_count).each do |i|
        config.vm.define "linode#{i}" do |linode|
            linode.vm.box = $linode_box_image
            linode.vm.hostname = "linux#{i}"
            linode.vm.network :private_network, ip: "#{$network}.#{i + 10}"
            linode.vm.provider "virtualbox" do |vb|
                vb.memory = $linode_ram
                vb.cpus = $linode_cpu
                vb.linked_clone = $linked_clone
            end
            linode.vm.provision "shell", inline: <<-SHELL
            #{$linux_config_dnsclient}
            SHELL
        end
    end

    (1..$winode_count).each do |x|
        config.vm.define "winode#{x}" do |winode|
            winode.vm.box = $winode_box_image
            winode.vm.hostname = "win#{x}"
            winode.vm.network :private_network, ip: "#{$network}.#{x + 100}" 
            winode.vm.provider "virtualbox" do |vb|
                vb.memory = $winode_ram
                vb.cpus = $winode_cpu
                vb.linked_clone = $linked_clone
            end
            if $win_clients_join_domain == true
                winode.vm.provision :shell do |joinad|
                    joinad.path = "scripts/join_domain.ps1"
                    joinad.args = "#{$domain_name} #{$domain_netbios_name} #{$network} #{$language}"
                end
                winode.vm.provision :windows_reboot    
            end 
            if $win_clients_join_domain == false
                winode.vm.provision :shell do |windns|
                    windns.path = "scripts/set_dns_server.ps1"
                    windns.args = "#{$network} #{$language}"
                end 
            end
        end
    end
end