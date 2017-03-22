require_relative "TaskConfig"
require_relative "VmManager"

class VmTask
    def initialize(config: TaskConfig.new)
        @config = config
    end

    def run
        fail NotImplementedError, "A canine class must be able to #bark!"
    end

    def with
        vm_manager = VmManager.new(@config.vm_name, @config.storage_folder)
        yield vm_manager
    end
end