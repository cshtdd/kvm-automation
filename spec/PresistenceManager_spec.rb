require 'PersistenceManager'
require 'fileutils'

describe 'PersistenceManager' do
    before do
        @temp_storage_root = File.join(FileUtils.pwd(), 'tmp_test')
        FileUtils.mkdir(@temp_storage_root) unless File.directory?(@temp_storage_root)
    end

    after do
        FileUtils.rm_rf(@temp_storage_root)
    end

    it 'generates the cloud_config in the correct location' do
        PersistenceManager.new()
    end
end