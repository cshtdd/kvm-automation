require_relative "TaskConfig"
require_relative "VmManager"

class VmTask
    def initialize(config: TaskConfig.new)
        @config = config
    end

    def run
        with do |vm_manager|
            run_with vm_manager
        end
    end

    def with
        yield VmManager.new(@config.vm_name, @config.storage_folder)
    end

    def run_with(vm_manager)
        fail NotImplementedError, "A VmTask must implement run_with(VmManager)"
    end
end