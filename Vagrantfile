# -*- mode: ruby -*-
# vi: set ft=ruby :
VAGRANTFILE_API_VERSION = "2"

VM_NAME = "my_stack"
MEMORY_SIZE_MB = 2046
NUMBER_OF_CPUS = 2

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "bento/ubuntu-16.04"

  config.vm.define "box" do |box|
    box.vm.provider "virtualbox" do |v|
      v.name = VM_NAME
      v.customize ["modifyvm", :id, "--memory", MEMORY_SIZE_MB]
      v.customize ["modifyvm", :id, "--cpus", NUMBER_OF_CPUS]
    end
    box.vm.network :private_network, ip: "192.168.55.55"
    box.vm.network :forwarded_port, guest: 80, host: 8080
    box.vm.provision :shell, :path => "provision.sh"
  end
end