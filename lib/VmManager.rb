require "fileutils"
require_relative "ShellUtils"
require_relative "ConfigBuilder"

class VmManager
    def initialize(vm_name, storage_root)
        @vm_name = vm_name
        @storage_root = File.join(storage_root, "#{@vm_name}/")
    end

    def config_folder
        @storage_root
    end

    def hdd_filename
        File.join(@storage_root, "#{@vm_name}.qcow2")
    end

    def hdd_container_folder
        File.dirname hdd_filename
    end

    def generate_vm_config_drive(public_key_filename)
        public_key = File.read public_key_filename

        cloud_config = ConfigBuilder.generate_cloud_config(public_key, @vm_name)

        save_cloud_config cloud_config
    end

    def save_cloud_config(file_contents)
        cloud_config_folder = File.join(config_folder, "openstack/latest/")
        config_filename = File.join(cloud_config_folder, "user_data")

        mkdir_p cloud_config_folder
        File.write(config_filename, file_contents)
    end

    def create_vm_hdd_container_folder
        mkdir_p hdd_container_folder
    end

    def create_vm_hdd(base_image)
        create_vm_hdd_container_folder()
        sh "qemu-img create -f qcow2 -b #{base_image} #{hdd_filename}"
    end

    def destroy_existing_vm
        `virsh destroy #{@vm_name}`
        `virsh undefine #{@vm_name}`
        `rm -Rf #{@storage_root}`
    end

    def autostart_vm
        sh "virsh autostart #{@vm_name}"
    end

    def create_coreos_vm(mac_address, bridge_adapter, ram_mb, hdd_gb, cpu_count)
        sh %{
            virt-install --connect qemu:///system \\
                --import --name #{@vm_name} \\
                --ram #{ram_mb} \\
                --size #{hdd_gb}G \\
                --vcpus #{cpu_count} \\
                --os-type=linux \\
                --os-variant=virtio26 \\
                --disk path=#{hdd_filename},format=qcow2,bus=virtio \\
                --filesystem #{config_folder},config-2,type=mount,mode=squash \\
                --network=bridge=#{bridge_adapter},mac=#{mac_address} \\
                --vnc --noautoconsole
        }
    end

    def create_ubuntu_vm(os_variant, base_image, mac_address, bridge_adapter, ram_mb, cpu_count, vnc_port, vnc_ip)
        sh %{
            virt-install --connect qemu:///system \\
                --virt-type=kvm \\
                --name #{@vm_name} \\
                --ram #{ram_mb} \\
                --vcpus=#{cpu_count} \\
                --os-variant=#{os_variant} \\
                --virt-type=kvm \\
                --hvm \\
                --cdrom=#{base_image} \\
                --network=bridge=#{bridge_adapter},model=virtio \\
                --mac="#{mac_address}" \\
                --graphics vnc,listen=0.0.0.0,port=#{vnc_port} \\
                --disk path=#{hdd_filename},size=10,bus=virtio,format=qcow2
        }
    end
end