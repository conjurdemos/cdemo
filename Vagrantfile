Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.provider "virtualbox" do |vbox|
    vbox.name = "cdemo"
    vbox.memory = 1024*8
    vbox.cpus = 4
  end
  config.vm.network "private_network", type: "dhcp"
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  config.vm.provision "ansible", type: "shell", inline: "/vagrant/bin/install-ansible"
  config.vm.provision "cdemo", type: "ansible_local" do |ansible|
    ansible.install = false
    ansible.become = true
    ansible.provisioning_path = "/vagrant/conjurDemo"
    ansible.inventory_path = "inventory.yml"
    ansible.playbook = "cDemo_start.yml"
  end
end
