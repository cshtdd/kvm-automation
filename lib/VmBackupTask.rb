require_relative "VmTask"

class VmBackupTask < VmTask
    def run_with(vm_manager)
        vm_manager.create_vm_backup_folder
    end
end