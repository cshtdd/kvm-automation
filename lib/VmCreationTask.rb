require_relative "TaskConfig"
require_relative "VmManager"

class VmCreationTask
    def initialize(config: TaskConfig.new)
        @config = config
    end

    def run
        vm_manager = VmManager.new(@config.vm_name, @config.storage_folder)

        vm_manager.destroy_existing_vm
        vm_manager.generate_vm_config_drive @config.public_key_filename
        vm_manager.create_vm_hdd @config.base_image_filename

        vm_manager.create_vm(
            @config.mac_address,
            @config.bridge_adapter,
            @config.ram_mb,
            @config.cpu_count
        )

        vm_manager.autostart_vm
    end

    def create_config
        vm_manager = VmManager.new(@config.vm_name, @config.storage_folder)
        vm_manager.generate_vm_config_drive @config.public_key_filename
    end
end