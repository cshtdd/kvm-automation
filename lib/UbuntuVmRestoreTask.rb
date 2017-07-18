require_relative "VmTask"

class UbuntuVmRestoreTask < VmTask
    def run_with(vm_manager)
        vm_manager.destroy_existing_vm

        vm_manager.create_vm_hdd_container_folder

        vm_manager.extract_vm_backup @config.base_image_filename

        vm_manager.restore_ubuntu_vm(
            @config.os_variant,
            @config.mac_address,
            @config.bridge_adapter,
            @config.ram_mb,
            @config.cpu_count,
            @config.vnc_port,
            @config.vnc_ip
        )
    end
end