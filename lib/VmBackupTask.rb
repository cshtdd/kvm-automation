require_relative "VmTask"

class VmBackupTask < VmTask
    def run_with(vm_manager)
        raise "Unknown vm #{@config.vm_name}" unless vm_manager.vm_already_exists

        vm_manager.cleanup_existing_vm_backup
        vm_manager.create_vm_backup_folder
        vm_manager.backup_vm
    end
end