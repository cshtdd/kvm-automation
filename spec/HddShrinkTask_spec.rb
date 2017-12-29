require "HddShrinkTask"
require "VmManager"
require "TaskConfig"

describe HddShrinkTask, "run" do
    before do
        @vm_manager = instance_double("VmManager").as_null_object
        @config = instance_double("TaskConfig").as_null_object
    end

    def run_task
        expect(VmManager).to receive(:new).and_return(@vm_manager)
        HddShrinkTask.new(config: @config).run
    end

    it "fails if the vm is already running" do
        expect(@vm_manager).to receive(:vm_is_running).and_return(true)

        expect { run_task }.to raise_error RuntimeError
    end

    it "shrinks the harddrive" do
        expect(@vm_manager).to receive(:vm_is_running).and_return(false)
        expect(@vm_manager).to receive(:shrink_hdd)

        run_task
    end

    it "promotes the shrinked hdd" do
        expect(@vm_manager).to receive(:vm_is_running).and_return(false)
        expect(@vm_manager).to receive(:promote_hdd_backup)

        run_task
    end
end