require "DeleteAllVmBackupsTask"
require "VmManager"
require "TaskConfig"

describe DeleteAllVmBackupsTask, "run" do
  it "deletes the backups" do
    @config = instance_double("TaskConfig").as_null_object

    @vm_manager = instance_double("VmManager").as_null_object
    expect(@vm_manager).to receive(:delete_all_existing_vm_backups)
    expect(VmManager).to receive(:new).and_return(@vm_manager)

    DeleteAllVmBackupsTask.new(config: @config).run
  end
end
