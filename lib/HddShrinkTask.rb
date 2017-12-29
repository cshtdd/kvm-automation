require_relative "VmTask"

class HddShrinkTask < VmTask
    def run_with(vm_manager)
        vm_manager.shrink_hdd
        vm_manager.promote_hdd_backup
    end
end