require_relative "VmTask"

class CoreOsVmCreationTask < VmTask
    def run_with(vm_manager)
        vm_manager.destroy_existing_vm
        vm_manager.generate_vm_config_drive @config.public_key_filename
        vm_manager.create_vm_hdd @config.base_image_filename

        vm_manager.create_coreos_vm(
            @config.mac_address,
            @config.bridge_adapter,
            @config.ram_mb,
            @config.hdd_gb,
            @config.cpu_count
        )

        vm_manager.autostart_vm
    end
end