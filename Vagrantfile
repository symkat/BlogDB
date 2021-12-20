# -*- mode: ruby -*-
# vi: set ft=ruby :

# https://docs.vagrantup.com.
Vagrant.configure("2") do |config|

  # Debian 11 box.
  config.vm.box = "debian/bullseye64"

  # Web app on port 8000 
  config.vm.network "forwarded_port", guest: 3000, host: 8000

  # Include our git repo as /home/vagrant/BlogDB
  config.vm.synced_folder "./", "/home/vagrant/BlogDB"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.name = "blogdb"
    vb.memory = "4096"
  end

  # Run the debian setup script, then the vagrant post install script.
  config.vm.provision "shell", after: "file", inline: <<-SHELL
    chmod 0755 /home/vagrant/BlogDB/system/setup-debian.sh
    chmod 0755 /home/vagrant/BlogDB/system/vagrant-post-install.sh
    /home/vagrant/BlogDB/system/setup-debian.sh
    su --login --shell /bin/bash -c '/home/vagrant/BlogDB/system/vagrant-post-install.sh' vagrant
  SHELL
end
