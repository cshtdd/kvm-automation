require "VmCreationTask"
require "VmManager"
require "TaskConfig"

describe VmCreationTask, "run" do
    before do
        @vm_manager = instance_double("VmManager").as_null_object

        @factory_stub = class_double("VmManagerFactory")
            .as_stubbed_const(:transfer_nested_constants => true)
    end

    it "generates the vm config drive" do
        config = instance_double("TaskConfig",
            :public_key_filename => "my key",
            :vm_name => "test vm",
            :storage_folder => "test storage"
        )
        expect(@vm_manager).to receive(:generate_vm_config_drive).with("my key")
        expect(@factory_stub).to receive(:create).with(config).and_return(@vm_manager)

        VmCreationTask.new(config: config).run
    end
end