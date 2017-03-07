require 'fileutils'

class PersistenceManager
    def initialize(storage_root)
        @storage_root = storage_root
    end

    def config_folder
        File.join(@storage_root, 'config/')
    end

    def save_cloud_config(file_contents)
        cloud_config_folder = File.join(config_folder, 'openstack/latest/')
        config_filename = File.join(cloud_config_folder, 'user_data')

        FileUtils.mkdir_p(cloud_config_folder)

        File.write(config_filename, file_contents)
    end

    def create_vm_hdd(base_image, vm_name)
        hdd_filename = File.join(@storage_root, "#{vm_name}.qcow2")
        sh "qemu-img create -f qcow2 -b #{base_image} #{hdd_filename}"
        hdd_filename
    end
end