require 'TempFolder'
require 'VmManager'

describe 'VmManager' do
    before do
        @tmp_root = TempFolder.new
        @vm_name = "tmp_vm_#{rand(100000)}"
        @m = VmManager.new(@vm_name, @tmp_root.path)
    end

    after do
        @tmp_root.destroy
    end

    it 'generates the cloud_config in the correct location' do
        @m.save_cloud_config('config contents')

        expected_file_path = File.join(@tmp_root.path, "#{@vm_name}/config/openstack/latest/user_data")

        expect(File.read(expected_file_path)).to eq('config contents')
    end

    it 'retrieves the config folder path' do
        expected_config_folder_path = File.join(@tmp_root.path, "#{@vm_name}/config/")

        expect(@m.config_folder).to eq(expected_config_folder_path)
    end

    it 'determines where to store the hdd' do
        expected_hdd_filename = File.join(@tmp_root.path, "#{@vm_name}/#{@vm_name}.qcow2")

        expect(@m.hdd_filename).to eq(expected_hdd_filename)
    end
end