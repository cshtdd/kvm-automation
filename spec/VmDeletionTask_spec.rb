require "VmDeletionTask"
require "VmManager"
require "TaskConfig"

describe VmDeletionTask, "run" do
    before do
        @vm_manager = instance_double("VmManager").as_null_object
    end

    def run_task
        expect(VmManager).to receive(:new).and_return(@vm_manager)
        VmDeletionTask.new(config: @config).run
    end

    it "creates a VmManager" do
        @config = instance_double("TaskConfig",
            :vm_name => "my vm",
            :storage_folder => "/tmp/storage"
        ).as_null_object

        expect(VmManager).to receive(:new).with("my vm", "/tmp/storage").and_return(@vm_manager)

        VmDeletionTask.new(config: @config).run
    end

    it "removes existing vms with that name" do
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:destroy_existing_vm)

        run_task
    end
end