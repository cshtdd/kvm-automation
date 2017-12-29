require "TempFolder"
require "fileutils"

describe TempFolder do
  def cleanup(temp_dir)
    FileUtils.rm_rf(temp_dir.path) if File.directory?(temp_dir.path)
  end

  it "creates a new directory" do
    d = TempFolder.new()

    begin
      expect(File.directory?(d.path)).to eq(true)
    ensure
      cleanup d
    end
  end

  it "destroys the directory" do
    d = TempFolder.new()

    begin
      d.destroy
      expect(File.directory?(d.path)).not_to eq(true)
    ensure
     cleanup d
   end
 end

 it "creates a different directory every time" do
  d1 = TempFolder.new()
  d2 = TempFolder.new()

  begin
    expect(File.directory?(d1.path)).to eq(true)
    expect(File.directory?(d2.path)).to eq(true)
    expect(d1.path).not_to eq(d2.path)
  ensure
    d1.destroy
    d2.destroy
  end
end
end