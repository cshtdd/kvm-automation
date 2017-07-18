require "VmBackupTask"
require "VmManager"
require "TaskConfig"

describe VmBackupTask, "run" do
    before do
        @vm_manager = instance_double("VmManager").as_null_object
    end

    def run_task
        expect(VmManager).to receive(:new).and_return(@vm_manager)
        VmBackupTask.new(config: @config).run
    end

    it "creates the backup container folder" do
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:create_vm_backup_folder)

        run_task
    end
end