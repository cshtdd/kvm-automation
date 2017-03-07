require 'TempFolder'
require 'PersistenceManager'

describe 'PersistenceManager' do
    before do
        @tmp_root = TempFolder.new
        @pm = PersistenceManager.new(@tmp_root.path)
    end

    after do
        @tmp_root.destroy
    end

    it 'generates the cloud_config in the correct location' do
        @pm.save_cloud_config('config contents')

        expected_file_path = File.join(@tmp_root.path, 'config/openstack/latest/user_data')

        expect(File.read(expected_file_path)).to eq('config contents')
    end

    it 'retrieves the config folder path' do
        expect_config_folder_path = File.join(@tmp_root.path, 'config/')

        expect(@pm.config_folder).to eq(expect_config_folder_path)
    end
end