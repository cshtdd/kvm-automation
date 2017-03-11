require "VmManager"

class VmManagerFactory
    def self.create(task_config)
        VmManager.new(task_config.vm_name, task_config.storage_folder)
    end
end
