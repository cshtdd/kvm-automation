require "CoreOsVmConfigTask"
require "VmManager"
require "TaskConfig"

describe CoreOsVmConfigTask, "run" do
    before do
        @vm_manager = instance_double("VmManager").as_null_object
    end

    def run_task
        expect(VmManager).to receive(:new).and_return(@vm_manager)
        CoreOsVmConfigTask.new(config: @config).run
    end

    it "creates a VmManager" do
        @config = instance_double("TaskConfig",
            :vm_name => "my vm",
            :storage_folder => "/tmp/storage"
        ).as_null_object

        expect(VmManager).to receive(:new).with("my vm", "/tmp/storage").and_return(@vm_manager)

        CoreOsVmConfigTask.new(config: @config).run
    end

    it "removes existing vms with that name" do
        @config = instance_double("TaskConfig",
            :public_key_filename => "secret-file.pub"
        ).as_null_object

        expect(@vm_manager).to receive(:generate_vm_config_drive).with("secret-file.pub")

        run_task
    end
end