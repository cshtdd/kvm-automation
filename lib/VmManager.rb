require "fileutils"

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
    end
end