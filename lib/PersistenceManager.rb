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
end