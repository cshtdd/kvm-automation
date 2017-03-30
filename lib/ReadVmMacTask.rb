require_relative "VmTask"

class ReadVmMacTask < VmTask
    def run_with(vm_manager)
        vm_manager.read_mac_address
    end
end