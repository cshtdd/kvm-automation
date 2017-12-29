require "ReadVmBackupPathTask"
require "VmManager"
require "TaskConfig"

describe ReadVmBackupPathTask, "run" do
  it "reads the mac address" do
    @config = instance_double("TaskConfig").as_null_object

    @vm_manager = instance_double("VmManager").as_null_object
    expect(@vm_manager).to receive(:read_latest_backup_filename)
    expect(VmManager).to receive(:new).and_return(@vm_manager)

    ReadVmBackupPathTask.new(config: @config).run
  end
end
