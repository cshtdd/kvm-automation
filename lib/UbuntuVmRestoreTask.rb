require_relative "VmTask"

class UbuntuVmRestoreTask < VmTask
    def run_with(vm_manager)
        raise "Backup file '#{@config.base_image_filename}' not found" unless File.file? @config.base_image_filename

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

        vm_manager.autostart_vm unless @config.autostart == "false"
        vm_manager.read_vnc_information
        vm_manager.read_mac_address
    end
end