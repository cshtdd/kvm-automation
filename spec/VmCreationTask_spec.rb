require "VmCreationTask"
require "VmManager"
require "TaskConfig"

describe VmCreationTask, "run" do
    it "generates the vm config drive" do
        vm_manager = instance_double("VmManager").as_null_object
        expect(vm_manager).to receive(:generate_vm_config_drive).with("my key")

        config = instance_double("TaskConfig",
            :public_key_filename => "my key",
            :vm_name => "test vm",
            :storage_folder => "test storage"
        )

        factory_stub = class_double("VmManagerFactory")
            .as_stubbed_const(:transfer_nested_constants => true)
        expect(factory_stub).to receive(:create).with(config).and_return(vm_manager)

        task = VmCreationTask.new(config: config)

        task.run
    end


end