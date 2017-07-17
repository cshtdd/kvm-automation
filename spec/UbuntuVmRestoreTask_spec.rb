require "UbuntuVmRestoreTask"
require "VmManager"
require "TaskConfig"

describe UbuntuVmRestoreTask, "run" do
    before do
        @vm_manager = instance_double("VmManager").as_null_object
    end

    def run_task
        expect(VmManager).to receive(:new).and_return(@vm_manager)
        UbuntuVmRestoreTask.new(config: @config).run
    end

    it "removes existing vms with that name" do
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:destroy_existing_vm)

        run_task
    end
end