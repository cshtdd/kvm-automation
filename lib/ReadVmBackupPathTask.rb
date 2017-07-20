require_relative "VmTask"

class ReadVmBackupPathTask < VmTask
    def run_with(vm_manager)
        vm_manager.read_latest_backup_filename
    end
end
