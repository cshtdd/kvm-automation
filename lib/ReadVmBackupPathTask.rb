require_relative "VmTask"

class ReadVmBackupPathTask < VmTask
  def run_with(vm_manager)
    puts vm_manager.read_latest_backup_filename
  end
end
