require "VmTask"
require "VmManager"
require "TaskConfig"

class VmTaskDummy < VmTask
    def run_with(vm_manager)
    end
end

describe VmTask, "run" do
    it "creates a VmManager" do
        @config = instance_double("TaskConfig",
            :vm_name => "my vm",
            :storage_folder => "/tmp/storage"
        ).as_null_object

        expect(VmManager).to receive(:new)
            .with("my vm", "/tmp/storage")
            .and_return(instance_double("VmManager").as_null_object)

        VmTaskDummy.new(config: @config).run
    end
end