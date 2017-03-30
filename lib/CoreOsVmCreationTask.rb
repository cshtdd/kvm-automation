require_relative "VmTask"

class CoreOsVmCreationTask < VmTask
    def run_with(vm_manager)
        vm_manager.destroy_existing_vm
        vm_manager.generate_vm_config_drive @config.public_key_filename
        vm_manager.create_vm_hdd(
            @config.base_image_filename,
            @config.hdd_gb
        )

        vm_manager.create_coreos_vm(
            @config.mac_address,
            @config.bridge_adapter,
            @config.ram_mb,
            @config.cpu_count
        )

        vm_manager.autostart_vm

        puts "The new machine mac address is: "
        puts vm_manager.read_mac_address
    end
end