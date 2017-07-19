require "UbuntuVmRestoreTask"
require "VmManager"
require "TaskConfig"

describe UbuntuVmRestoreTask, "run" do
    before do
        @vm_manager = instance_double("VmManager").as_null_object
    end

    def run_task
        expect(VmManager).to receive(:new).and_return(@vm_manager)
        UbuntuVmRestoreTask.new(config: @config).run
    end

    it "removes existing vms with that name" do
        allow(File).to receive(:file?).and_return true
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:destroy_existing_vm)

        run_task
    end

    it "creates the hdd container folder" do
        allow(File).to receive(:file?).and_return true
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:create_vm_hdd_container_folder)

        run_task
    end

    it "raises an error if the backup file does not exists" do
        allow(File).to receive(:file?).and_return false
        @config = instance_double("TaskConfig",
            :base_image_filename => "backups/disk1.img.gz"
        ).as_null_object

        expect { run_task }.to raise_error
    end

    it "extracts the compressed backup" do
        allow(File).to receive(:file?).and_return true
        @config = instance_double("TaskConfig",
            :base_image_filename => "backups/disk1.img.gz"
        ).as_null_object

        expect(@vm_manager).to receive(:extract_vm_backup).with("backups/disk1.img.gz")

        run_task
    end

    it "restores the vm" do
        allow(File).to receive(:file?).and_return true
        @config = instance_double("TaskConfig",
            :os_variant => "minix",
            :mac_address => "my mac",
            :bridge_adapter => "br-test",
            :ram_mb => "12345",
            :cpu_count => "10",
            :vnc_port => "6800",
            :vnc_ip => "127.0.0.1"
        ).as_null_object

        expect(@vm_manager).to receive(:restore_ubuntu_vm).with(
            "minix", "my mac", "br-test", "12345", "10", "6800", "127.0.0.1"
        )

        run_task
    end

    it "autostarts the vm" do
        allow(File).to receive(:file?).and_return true
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:autostart_vm)

        run_task
    end

    it "displays the vm mac address" do
        allow(File).to receive(:file?).and_return true
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:read_mac_address)

        run_task
    end

    it "displays the vnc port" do
        allow(File).to receive(:file?).and_return true
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:read_vnc_information)

        run_task
    end
end