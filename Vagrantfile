#
# Vagrantfile
# Created: 6/30/18
# Log:
# 6/30/18 Created and incorporated JSON VM file into Vagrantfile
# 7/12/18 Add code to write the IP Address to IP File.
# 7/14/18 Fixed severity 1 issue with shares being defined.
# 7/15/18 Defining deploy sequence for IP Sync component
# 7/29/18 Added vagrant user to virtualbox group for shares

VAGRANT_API_VERSION = "2"
nodes_config = JSON.parse(File.read("d:/bdb/VM_Machine.json"))

# Constant block
IPFILE = "ipfile.txt"
VBOXSTORE = "D:/VirtualBox VMs"
VBOXEXT = ".vbox-prev"

Install_UpdateHost_Service = <<-UPDATE_HOST_SERVICE
sudo cp /tmp/updatehostsfile.service /etc/systemd/system/updatehostsfile.service
sudo cp /tmp/updatehostsfile.timer /etc/systemd/system/updatehostsfile.timer
sudo cp /tmp/UpdateHostsFile.sh /root/UpdateHostsFile.sh

sudo usermod -a -G vboxsf vagrant
sudo chmod 750 /root/UpdateHostsFile.sh
sudo chmod 644 /etc/systemd/system/updatehostsfile.service
sudo chmod 644 /etc/systemd/system/updatehostsfile.timer

sudo systemctl enable -l updatehostsfile.service
sudo systemctl enable -l updatehostsfile.timer
sudo systemctl start -l updatehostsfile.service
sudo systemctl start -l updatehostsfile.timer
UPDATE_HOST_SERVICE

def shared_defined(node, share_name)
  search_pattern = "SharedFolder name=\"#{share_name}\""
  if File.exists?(File.join(VBOXSTORE, node, "#{node}#{VBOXEXT}"))
  then
    File.open(File.join(VBOXSTORE, node, "#{node}#{VBOXEXT}")).grep(/#{search_pattern}/).size > 0
  else
    false
  end
end


Vagrant.configure(VAGRANT_API_VERSION) do | config |
  nodes_config["vm_machines"].each { | node_array_entry |

    config.vm.define node_array_entry["node"] do | define_host |
      # We need to configure EACH port defined for the vm machine.
      ports = node_array_entry["ports"]
      ports.each { | port |
        define_host.vm.network :forwarded_port, guest: port["guest"], host: port["host"]
      }

      if ARGV[0] == "up"
      then
        if ! File.exists?(File.join(node_array_entry["shared"][0]["host"], IPFILE))
        then
          FileUtils.touch(File.join(node_array_entry["shared"][0]["host"], IPFILE))
        end

        if File.open(File.join(node_array_entry["shared"][0]["host"], IPFILE)).grep(/#{node_array_entry["ip"]}/).size == 0
          File.open(File.join(node_array_entry["shared"][0]["host"], IPFILE),"a") do | textfile |
            textfile.puts "#{node_array_entry["ip"]}          #{node_array_entry["node"]}"
          end
        end
      end

      # We also need to confiure EACH share for the VM machine.
      shared = node_array_entry["shared"]
      define_host.vm.provider "virtualbox" do | vb |
        vb.customize ["modifyvm", :id, "--memory", node_array_entry["memory"]]
        vb.customize ["modifyvm", :id, "--name", node_array_entry["node"]]

        shared.each { | share |
          if ! shared_defined(node_array_entry["node"], share["name"])
            vb.customize ["sharedfolder", "add", :id, "--name", share["name"], "--hostpath", share["host"], "--automount"]
          end
        }

      end
      define_host.vm.box = node_array_entry["box"]
      define_host.vm.hostname = node_array_entry["node"]
      define_host.vm.network :private_network, ip: node_array_entry["ip"]

      define_host.vm.provision "file", source: "dirshare/updatehostsfile.service", destination: "/tmp/updatehostsfile.service" 
      define_host.vm.provision "file", source: "dirshare/updatehostsfile.timer", destination: "/tmp/updatehostsfile.timer" 
      define_host.vm.provision "file", source: "dirshare/UpdateHostsFile.sh", destination: "/tmp/UpdateHostsFile.sh"
      define_host.vm.provision "shell", inline: Install_UpdateHost_Service
    end
  }
end
