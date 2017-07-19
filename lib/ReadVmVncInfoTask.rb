require_relative "VmTask"

class ReadVmVncInfoTask < VmTask
    def run_with(vm_manager)
        vm_manager.read_vnc_information
    end
end
