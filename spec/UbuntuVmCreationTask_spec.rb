require "UbuntuVmCreationTask"
require "VmManager"
require "TaskConfig"

describe UbuntuVmCreationTask, "run" do
    before do
        @vm_manager = instance_double("VmManager").as_null_object
    end

    def run_task
        expect(VmManager).to receive(:new).and_return(@vm_manager)
        UbuntuVmCreationTask.new(config: @config).run
    end

    it "removes existing vms with that name" do
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:destroy_existing_vm)

        run_task
    end

    it "creates the hdd container folder" do
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:create_vm_hdd_container_folder)

        run_task
    end

    it "creates the vm" do
        @config = instance_double("TaskConfig",
            :os_variant => "minix",
            :base_image_filename => "my_iso.iso",
            :mac_address => "my mac",
            :bridge_adapter => "br-test",
            :ram_mb => "12345",
            :cpu_count => "10",
            :hdd_gb => "15",
            :vnc_port => "6800",
            :vnc_ip => "127.0.0.1"
        ).as_null_object

        expect(@vm_manager).to receive(:create_ubuntu_vm).with(
            "minix", "my_iso.iso", "my mac", "br-test", "12345", "10", "15", "6800", "127.0.0.1"
        )

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