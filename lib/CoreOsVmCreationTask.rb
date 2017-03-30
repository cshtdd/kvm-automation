require_relative "VmTask"

class CoreOsVmCreationTask < VmTask
    def run_with(vm_manager)
        vm_manager.destroy_existing_vm
        vm_manager.generate_vm_config_drive @config.public_key_filename

        base_image_filename = @config.base_image_filename
        if @config.download_image == "true" then
            vm_manager.download_coreos_latest_stable_image
            base_image_filename = vm_manager.coreos_image_filename
        end

        vm_manager.create_vm_hdd(base_image_filename, @config.hdd_gb)

        vm_manager.create_coreos_vm(
            @config.mac_address,
            @config.bridge_adapter,
            @config.ram_mb,
            @config.cpu_count
        )

        vm_manager.autostart_vm

        vm_manager.read_mac_address
    end
end