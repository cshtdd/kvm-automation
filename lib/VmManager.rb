require "fileutils"
require_relative "ShellUtils"
require_relative "ConfigBuilder"

class VmManager
    def initialize(vm_name, storage_root)
        @vm_name = vm_name
        @storage_root = File.join(storage_root, "#{@vm_name}/")
    end

    def config_folder
        File.join(@storage_root, "config/")
    end

    def hdd_filename
        File.join(@storage_root, "#{@vm_name}.qcow2")
    end

    def generate_vm_config_drive(public_key_filename)
        public_key = File.read public_key_filename

        ConfigBuilder.generate_cloud_config(public_key, @vm_name)
    end

    def save_cloud_config(file_contents)
        cloud_config_folder = File.join(config_folder, "openstack/latest/")
        config_filename = File.join(cloud_config_folder, "user_data")

        FileUtils.mkdir_p(cloud_config_folder)

        File.write(config_filename, file_contents)
    end

    def create_vm_hdd(base_image)
        sh "qemu-img create -f qcow2 -b #{base_image} #{hdd_filename}"
    end

    def destroy_existing_vm
        `virsh destroy #{@vm_name}`
        `virsh undefine #{@vm_name}`
    end

    def autostart_vm
        sh "virsh autostart #{@vm_name}"
    end

    def create_vm(mac_address, bridge_adapter, ram_mb, cpu_count)
        sh %{
            virt-install --connect qemu:///system \\
                --import --name #{@vm_name} \\
                --ram #{ram_mb} \\
                --vcpus #{cpu_count} \\
                --os-type=linux \\
                --os-variant=virtio26 \\
                --disk path=#{hdd_filename},format=qcow2,bus=virtio \\
                --filesystem #{config_folder},config-2,type=mount,mode=squash \\
                --network=bridge=#{bridge_adapter},mac=#{mac_address} \\
                --vnc --noautoconsole
        }
    end
end