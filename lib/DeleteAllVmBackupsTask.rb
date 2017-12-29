require_relative "VmTask"

class DeleteAllVmBackupsTask < VmTask
  def run_with(vm_manager)
    vm_manager.delete_all_existing_vm_backups
  end
end
