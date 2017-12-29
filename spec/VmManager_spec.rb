require "TempFolder"
require "VmManager"
require "ShellUtils"

describe VmManager do
    before do
        @tmp_root = TempFolder.new
        @vm_name = "tmp_vm_#{rand(100000)}"

        allow(Time).to receive(:now).and_return(Time.mktime(1990,12,1, 5,32,23))
        @m = VmManager.new(@vm_name, @tmp_root.path)
    end

    after do
        @tmp_root.destroy
    end

    it "generates the cloud_config in the correct location" do
        @m.save_cloud_config("config contents")

        expected_file_path = File.join(@tmp_root.path, "#{@vm_name}/openstack/latest/user_data")

        expect(File.read(expected_file_path)).to eq "config contents"
    end

    it "retrieves the config folder path" do
        expected_config_folder_path = File.join(@tmp_root.path, "#{@vm_name}/")

        expect(@m.config_folder).to eq expected_config_folder_path
    end

    it "determines where to store the hdd" do
        expected_hdd_filename = File.join(@tmp_root.path, "#{@vm_name}/#{@vm_name}.qcow2")

        expect(@m.hdd_filename).to eq expected_hdd_filename
    end

    it "shrinks the hdd" do
        expect(FileUtils).to receive(:mv).with("#{@m.hdd_filename}.bck", @m.hdd_filename).once
        expect(FileUtils).to receive(:rm).with(@m.hdd_filename).once

        @m.shrink_hdd
    end

    it "determines where to store the coreos image" do
        expect_coreos_image_filename = File.join(@tmp_root.path, "#{@vm_name}/coreos_production_qemu_image.img")

        expect(@m.coreos_image_filename).to eq expect_coreos_image_filename
    end

    it "determines where to store the backup" do
        expected_backup_folder_path = File.join(@tmp_root.path, "#{@vm_name}/")

        expect(@m.backup_folder).to eq expected_backup_folder_path
    end

    it "determines the snapshot folder" do
        expected_snapshot_folder_path = File.join(@tmp_root.path, "#{@vm_name}/19901201053223/")

        expect(@m.snapshot_folder).to eq expected_snapshot_folder_path
    end

    it "determines the path of the most recent snapshot" do
        seeded_images = [
            mock_snapshot("20011201000000"),
            mock_snapshot("20031201000000"),
            mock_snapshot("20021201000000")
        ]

        expect(@m.read_latest_backup_filename).to eq seeded_images[1]
    end

    it "raises an error when there are no snapshots" do
        expect { @m.read_latest_backup_filename }.to raise_error RuntimeError
    end

    private def mock_snapshot(snapshot_name)
        snapshot_folder = File.join(@m.backup_folder, "#{snapshot_name}/#{@vm_name}")
        mkdir_p snapshot_folder

        img_file = File.join(snapshot_folder, "#{@vm_name}_hdd1.img.gz")
        `touch #{img_file}`

        img_file
    end
end
