require "TaskConfig"

describe TaskConfig do
  it "returns default values when nothing is specified" do
    r = TaskConfig.new()

    expect(r.storage_folder).to eq(File.expand_path("~/vms"))
    expect(r.public_key_filename).to eq(File.expand_path("~/.ssh/id_rsa.pub"))
    expect(r.base_image_filename).to eq("")
    expect(r.download_image).to eq("false")
    expect(r.autostart).to eq("true")
    expect(r.vm_name).to eq("vm01")
    expect(r.mac_address).to eq("")
    expect(r.bridge_adapter).to eq("br0")
    expect(r.ram_mb).to eq("1024")
    expect(r.hdd_gb).to eq("10")
    expect(r.cpu_count).to eq("1")
    expect(r.os_variant).to eq("")
    expect(r.vnc_port).to eq("")
    expect(r.vnc_ip).to eq("0.0.0.0")
  end

  it "parses the parameters" do
    r = TaskConfig.new([
      "--path", "/var/vms/data",
      "--key", "/etc/secrets/key.pub",
      "--img", "~/ubuntu.img",
      "--dwnld", "true",
      "--autostart", "false",
      "--name", "vm45",
      "--mac", "00:00:00:01",
      "--br", "vbr1",
      "--ram", "2048",
      "--hdd", "20",
      "--cpu", "4",
      "--os-variant", "ubuntu16.04",
      "--vnc-port", "5901",
      "--vnc-ip", "127.0.0.1"])

    expect(r.storage_folder).to eq("/var/vms/data")
    expect(r.public_key_filename).to eq("/etc/secrets/key.pub")
    expect(r.base_image_filename).to eq(File.expand_path("~/ubuntu.img"))
    expect(r.download_image).to eq("true")
    expect(r.autostart).to eq("false")
    expect(r.vm_name).to eq("vm45")
    expect(r.mac_address).to eq("00:00:00:01")
    expect(r.bridge_adapter).to eq("vbr1")
    expect(r.ram_mb).to eq("2048")
    expect(r.hdd_gb).to eq("20")
    expect(r.cpu_count).to eq("4")
    expect(r.os_variant).to eq("ubuntu16.04")
    expect(r.vnc_port).to eq("5901")
    expect(r.vnc_ip).to eq("127.0.0.1")
  end
end