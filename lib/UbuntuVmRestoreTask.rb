require_relative "VmTask"

class UbuntuVmRestoreTask < VmTask
    def run_with(vm_manager)
        vm_manager.destroy_existing_vm
    end
end