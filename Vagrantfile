# -*- mode: ruby -*-
# vi: set ft=ruby :
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
# If deploying both Windows and Linux VMs, linode_count must not exceed 89
# otherwise you have duplicate IPs assigned to overlapping VMs
$linode_count = 2 
$linode_cpu = 1
$linode_ram = 1024
$linode_box_image = "centos/7"

# Windows Nodes
###############
# winode_count must not exceed 154 or you'll get nonsensical IP addresses
$winode_count = 2
$winode_cpu = 1
$winode_ram = 2048
$winode_box_image = "opentable/win-2012r2-standard-amd64-nocm"

# Windows AD Control
###
### Removing AD stuff because Windows is a massive bag of spanners
###

#$enable_ad = true
#$dc_cpu = 2
#$dc_ram = 4096
#$domain_name = "mytest.local"
#$domain_netbios_name = "mytest"
#$domain_admin_password = "Pa55w0rd!"
#$safe_mode_admin_password = "Pa55w0rd!"
#$win_clients_join_domain = true

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

SCRIPT

# TO-DO LIST
#
# Script network configuration for Windows (e.g. DNS server, domain search)
# Sysprep windows clients, generlize to generate new SID using answerfile.
# Work out how to reboot properly (windows)
# Script basic package configuration for Linux / Windows
# Script Ansible server install for master and client ssh key/winrm configuration
# Script saltstack server / minion install
# Script chef server / client install

$linked_clone = true

Vagrant.configure("2") do |config|
    config.winrm.transport = :plaintext
    config.winrm.basic_auth_only = true
    config.vm.synced_folder '.', '/vagrant', disabled: true

    #if $enable_ad == true
    #    config.vm.define "dc" do |dc|
    #        dc.vm.box = $winode_box_image
    #        dc.vm.hostname = "windc"
    #        dc.vm.communicator = "winrm"
    #        dc.vm.provision :shell do |adds|
    #            adds.path = "scripts/configure_dc.ps1"
    #            adds.args = "#{$domain_name} #{$domain_netbios_name} #{$safe_mode_admin_password} #{$network} #{$linode_count} #{$winode_count} #{$domain_admin_password}"
    #            end
    #        dc.vm.network :private_network, ip: "#{$network}.9"
    #        dc.vm.network :forwarded_port, 
    #            host: 9389,
    #            guest: 3389,
    #            id: "rdp",
    #            auto_correct: true            
    #        dc.vm.provider "virtualbox" do |vb|
    #            vb.memory = $dc_ram
    #            vb.cpus = $dc_cpu
    #            vb.linked_clone = $linked_clone
    #        dc.vm.provision :windows_reboot
    #        end
    #    end
    #end

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
        #if $enabled_ad == false # We only install and configure DNSmasq if AD isn't being used. Sacking off AD shite.
        master.vm.provision "shell", inline: <<-SHELL
        #{$linux_dnsmasq}
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
            #echo "Configuring Linux Node "#{i}"
            # SHELL SCRIPTS GO HERE.
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
            #winode.vm.provision :windows_reboot
            #echo "Configuring Windows Node #{x}"
            # SCRIPTS GO HERE 
        end
    end
end