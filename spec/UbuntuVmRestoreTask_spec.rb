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
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:destroy_existing_vm)

        run_task
    end

    it "creates the hdd container folder" do
        @config = instance_double("TaskConfig").as_null_object

        expect(@vm_manager).to receive(:create_vm_hdd_container_folder)

        run_task
    end

    it "extracts the compressed backup" do 
        @config = instance_double("TaskConfig",
            :base_image_filename => "backups/disk1.img.gz"
        ).as_null_object

        expect(@vm_manager).to receive(:extract_vm_backup).with("backups/disk1.img.gz")

        run_task
    end
end