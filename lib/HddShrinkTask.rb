require_relative "VmTask"

class HddShrinkTask < VmTask
    def run_with(vm_manager)
        raise "Vm '#{@config.vm_name}' cannot be running" if vm_manager.vm_is_running

        vm_manager.shrink_hdd
        vm_manager.promote_hdd_backup
    end
end