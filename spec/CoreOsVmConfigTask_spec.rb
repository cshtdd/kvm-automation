require "CoreOsVmConfigTask"
require "VmManager"
require "TaskConfig"

describe CoreOsVmConfigTask, "run" do
  it "removes existing vms with that name" do
    @config = instance_double("TaskConfig",
      :public_key_filename => "secret-file.pub"
      ).as_null_object

    @vm_manager = instance_double("VmManager").as_null_object
    expect(@vm_manager).to receive(:generate_vm_config_drive).with("secret-file.pub")
    expect(VmManager).to receive(:new).and_return(@vm_manager)

    CoreOsVmConfigTask.new(config: @config).run
  end
end