require_relative "VmTask"

class VmBackupTask < VmTask
    def run_with(vm_manager)
        vm_manager.cleanup_existing_vm_backup
        vm_manager.create_vm_backup_folder
        vm_manager.backup_vm
    end
end