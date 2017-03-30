require "CoreOsVmCreationTask"
require "VmManager"
require "TaskConfig"

describe CoreOsVmCreationTask, "run" do
    before do
        @vm_manager = instance_double("VmManager").as_null_object
    end

    def run_task
        expect(VmManager).to receive(:new).and_return(@vm_manager)
        CoreOsVmCreationTask.new(config: @config).run
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
            :base_image_filename => "seeded_base_image.img",
            :hdd_gb => "15"
        ).as_null_object

        expect(@vm_manager).to receive(:create_vm_hdd).with("seeded_base_image.img", "15")

        run_task
    end

    it "creates the vm" do
        @config = instance_double("TaskConfig",
            :mac_address => "my mac",
            :bridge_adapter => "br-test",
            :ram_mb => "12345",
            :cpu_count => "10"
        ).as_null_object

        expect(@vm_manager).to receive(:create_coreos_vm).with("my mac", "br-test", "12345", "10")

        run_task
    end

    it "autostarts the vm" do
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:autostart_vm)

        run_task
    end

    it "displays the vm mac address" do
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:read_mac_address)

        run_task
    end
end