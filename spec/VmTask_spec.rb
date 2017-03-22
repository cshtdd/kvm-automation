require "VmTask"
require "VmManager"
require "TaskConfig"

class VmTaskDummy < VmTask
    def run_with(vm_manager)
    end
end

describe VmTask, "run" do
    before do
        @vm_manager = instance_double("VmManager").as_null_object
    end

    def run_task
        expect(VmManager).to receive(:new).and_return(@vm_manager)
        VmTaskDummy.new(config: @config).run
    end

    it "creates a VmManager" do
        @config = instance_double("TaskConfig",
            :vm_name => "my vm",
            :storage_folder => "/tmp/storage"
        ).as_null_object

        expect(VmManager).to receive(:new).with("my vm", "/tmp/storage").and_return(@vm_manager)

        VmTaskDummy.new(config: @config).run
    end
end