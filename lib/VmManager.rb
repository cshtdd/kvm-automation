require "fileutils"
require_relative "ShellUtils"
require_relative "ConfigBuilder"

class VmManager
    def initialize(vm_name, storage_root)
        @vm_name = vm_name
        @storage_root = File.join(storage_root, "#{@vm_name}/")
        @creation_time = Time.now
    end

    def config_folder
        @storage_root
    end

    def backup_folder
        @storage_root
    end

    def snapshot_folder
        folder_name = @creation_time.strftime("%Y%m%d%H%M%S")
        File.join(backup_folder, "#{folder_name}/")
    end

    def hdd_filename
        File.join(@storage_root, "#{@vm_name}.qcow2")
    end

    def hdd_container_folder
        File.dirname hdd_filename
    end

    def coreos_image_container_folder
        @storage_root
    end

    def coreos_image_filename
        File.join(@storage_root, "coreos_production_qemu_image.img")
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

    def create_coreos_image_container_folder
        mkdir_p coreos_image_container_folder
    end

    def create_vm_hdd(base_image, hdd_gb)
        create_vm_hdd_container_folder()
        sh "qemu-img create -f qcow2 -b #{base_image} #{hdd_filename} #{hdd_gb}G"
    end

    def destroy_existing_vm
        `virsh destroy #{@vm_name}`
        `virsh undefine #{@vm_name}`
        `rm -Rf #{@storage_root}`
    end

    def autostart_vm
        sh "virsh autostart #{@vm_name}"
    end

    def read_mac_address
        sh "virsh dumpxml #{@vm_name} | grep \"mac address\""
    end

    def read_vnc_information
        sh "virsh dumpxml #{@vm_name} | grep \"vnc\""
    end

    def vm_already_exists
        sh "virsh list --name | grep \"#{@vm_name}\""
    end

    def build_mac_address_str(mac_address)
        mac_address = mac_address || ""
        mac_address_str = ""
        if not mac_address.empty? then
            mac_address_str = ",mac=#{mac_address}"
        end
        mac_address_str
    end

    def build_vnc_port_str(vnc_port)
        vnc_port = vnc_port || ""
        vnc_port_str = ""

        if not vnc_port.empty? then
            vnc_port_str = ",port=#{vnc_port}"
        end
        vnc_port_str
    end

    def create_coreos_vm(mac_address, bridge_adapter, ram_mb, cpu_count)
        mac_address_str = build_mac_address_str mac_address

        sh %{
            virt-install --connect qemu:///system \\
                --import --name #{@vm_name} \\
                --ram #{ram_mb} \\
                --vcpus #{cpu_count} \\
                --os-type=linux \\
                --os-variant=virtio26 \\
                --disk path=#{hdd_filename},format=qcow2,bus=virtio \\
                --filesystem #{config_folder},config-2,type=mount,mode=squash \\
                --network=bridge=#{bridge_adapter}#{mac_address_str} \\
                --vnc --noautoconsole
        }
    end

    def create_ubuntu_vm(os_variant, base_image, mac_address, bridge_adapter, ram_mb, cpu_count, hdd_gb, vnc_port, vnc_ip)
        mac_address_str = build_mac_address_str mac_address
        vnc_port_str = build_vnc_port_str vnc_port

        sh %{
            virt-install --connect qemu:///system \\
                --virt-type=kvm \\
                --name #{@vm_name} \\
                --ram #{ram_mb} \\
                --vcpus=#{cpu_count} \\
                --os-variant=#{os_variant} \\
                --virt-type=kvm \\
                --noautoconsole \\
                --hvm \\
                --cdrom=#{base_image} \\
                --network=bridge=#{bridge_adapter},model=virtio #{mac_address_str}\\
                --graphics vnc,listen=#{vnc_ip}#{vnc_port_str} \\
                --disk path=#{hdd_filename},size=#{hdd_gb},bus=virtio,format=qcow2
        }
    end

    def delete_all_existing_vm_backups
        sh "rm -Rf #{backup_folder}"
    end

    def create_vm_snapshot_folder
        mkdir_p snapshot_folder
    end

    def backup_utility_full_path
        lib_dir = File.dirname(__FILE__)
        backup_script_full_path = File.join(lib_dir, "resources/virt-backup.pl")
        backup_script_full_path
    end

    def backup_vm
        sh %{
            perl #{backup_utility_full_path} \\
                --vm=#{@vm_name} \\
                --backupdir=#{snapshot_folder} \\
                --compress
        }
    end

    def extract_vm_backup(base_image)
        sh %{
            gzip -dc #{base_image} | dd of=#{hdd_filename}
        }
    end

    def read_latest_backup_filename
        backup_container = File.join(snapshot_folder, "#{@vm_name}")
        puts Dir["#{backup_container}/#{@vm_name}_*.img.gz"]
    end

    def restore_ubuntu_vm(os_variant, mac_address, bridge_adapter, ram_mb, cpu_count, vnc_port, vnc_ip)
        mac_address_str = build_mac_address_str mac_address
        vnc_port_str = build_vnc_port_str vnc_port

        sh %{
            virt-install --connect qemu:///system \\
                --virt-type=kvm \\
                --name #{@vm_name} \\
                --ram #{ram_mb} \\
                --vcpus=#{cpu_count} \\
                --os-variant=#{os_variant} \\
                --virt-type=kvm \\
                --import \\
                --noautoconsole \\
                --hvm \\
                --network=bridge=#{bridge_adapter},model=virtio #{mac_address_str}\\
                --graphics vnc,listen=#{vnc_ip}#{vnc_port_str} \\
                --disk path=#{hdd_filename},bus=virtio,format=qcow2
        }
    end

    def download_coreos_latest_stable_image
        create_coreos_image_container_folder()
        Dir.chdir(coreos_image_container_folder) do
            sh "wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2"
            sh "bzip2 -d coreos_production_qemu_image.img.bz2"
        end
    end
end