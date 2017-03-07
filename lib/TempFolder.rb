require "fileutils"
require "tmpdir"

class TempFolder
    def path
        @temp_path
    end

    def initialize
        @temp_path = Dir.mktmpdir
    end

    def destroy
        FileUtils.rm_rf @temp_path
    end
end