# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # VBoxManage customization
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--memory", "1024"]
    v.customize ["modifyvm", :id, "--cpus", "1"]
  end

  # Forward SSH agent to host
  config.ssh.forward_agent = true

  #config.vm.share_folder "v-root", "/vagrant", ".", :nfs => true
  #config.vm.provision :shell, :path => "vagrant/package_provision.sh"
  #config.vm.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]

  ### Ubuntu 12.04 (precise) 64bit ###
  # CKAN 2.2 package
  config.vm.define "pkg22" do |pkg22|
    # Vagrant box configuration
    pkg22.vm.box = "precise64"
    pkg22.vm.box_url = "http://files.vagrantup.com/precise64.box"
    # Bootstrap script
    pkg22.vm.provision :shell, :path => "vagrant/precise64/pkg22/provision.sh"
    # Port forwarding
    pkg22.vm.network :forwarded_port, guest: 8080, host: 8080
  end

  # CKAN 2.0 package
  config.vm.define "pkg20" do |pkg20|
    # Vagrant box configuration
    pkg20.vm.box = "precise64"
    pkg20.vm.box_url = "http://files.vagrantup.com/precise64.box"
    # Bootstrap script
    pkg20.vm.provision :shell, :path => "vagrant/precise64/pkg20/provision.sh"
    # Port forwarding
    pkg20.vm.network :forwarded_port, guest: 8080, host: 8080
  end

  # CKAN source
  config.vm.define "precise64" do |precise64|
    # Vagrant box configuration
    precise64.vm.box = "precise64"
    precise64.vm.box_url = "http://files.vagrantup.com/precise64.box"
    # Bootstrap script
    precise64.vm.provision :shell, :path => "vagrant/precise64/src/provision.sh"
    # Port forwarding
    precise64.vm.network :forwarded_port, guest: 5000, host: 5000
    precise64.vm.network :forwarded_port, guest: 8080, host: 8080
  end

end
