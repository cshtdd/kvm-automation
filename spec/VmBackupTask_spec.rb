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

    it "fails if the vm does not exist" do
        allow(@vm_manager).to receive(:vm_already_exists).and_return false
        @config = instance_double("TaskConfig").as_null_object

        expect { run_task }.to raise_error
    end

    it "creates the backup container folder" do
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:create_vm_snapshot_folder)

        run_task
    end

    it "creates the backup" do
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:backup_vm)

        run_task
    end

    it "displays the backup file" do
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:read_latest_backup_filename)

        run_task
    end
end