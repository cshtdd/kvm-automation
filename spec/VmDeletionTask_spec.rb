require "VmDeletionTask"
require "VmManager"
require "TaskConfig"

describe VmDeletionTask, "run" do
    it "removes existing vms with that name" do
        @config = instance_double("TaskConfig").as_null_object

        @vm_manager = instance_double("VmManager").as_null_object
        expect(@vm_manager).to receive(:destroy_existing_vm)
        expect(VmManager).to receive(:new).and_return(@vm_manager)

        VmDeletionTask.new(config: @config).run
    end
end