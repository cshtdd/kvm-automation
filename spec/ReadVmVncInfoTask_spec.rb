require "ReadVmVncInfoTask"
require "VmManager"
require "TaskConfig"

describe ReadVmVncInfoTask, "run" do
  it "reads the mac address" do
    @config = instance_double("TaskConfig").as_null_object

    @vm_manager = instance_double("VmManager").as_null_object
    expect(@vm_manager).to receive(:read_vnc_information)
    expect(VmManager).to receive(:new).and_return(@vm_manager)

    ReadVmVncInfoTask.new(config: @config).run
  end
end
