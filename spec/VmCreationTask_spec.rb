require "VmCreationTask"
require "VmManager"
require "TaskConfig"

describe VmCreationTask, "run" do
    before do
        @vm_manager = instance_double("VmManager").as_null_object

        @factory_stub = class_double("VmManagerFactory")
            .as_stubbed_const(:transfer_nested_constants => true)
    end

    def run_task
        expect(@factory_stub).to receive(:create).with(@config).and_return(@vm_manager)
        VmCreationTask.new(config: @config).run
    end

    it "removes existing vms with that name" do
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:destroy_existing_vm)

        run_task
    end

    it "generates the vm config drive" do
        @config = instance_double("TaskConfig",
            :public_key_filename => "my key"
        ).as_null_object

        expect(@vm_manager).to receive(:generate_vm_config_drive).with("my key")

        run_task
    end

    it "generates the hdd" do
        @config = instance_double("TaskConfig",
            :base_image_filename => "seeded_base_image.img"
        ).as_null_object

        expect(@vm_manager).to receive(:create_vm_hdd).with("seeded_base_image.img")

        run_task
    end

    it "autostarts the vm" do
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:autostart_vm)

        run_task
    end
end