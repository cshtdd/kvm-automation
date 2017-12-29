require_relative "VmTask"

class VmBackupTask < VmTask
  def run_with(vm_manager)
    raise "Unknown vm #{@config.vm_name}" unless vm_manager.vm_already_exists

    vm_manager.create_vm_snapshot_folder
    vm_manager.backup_vm

    puts vm_manager.read_latest_backup_filename
  end
end
