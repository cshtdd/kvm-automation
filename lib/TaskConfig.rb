class TaskConfig
    attr_reader(
        :storage_folder,
        :public_key_filename,
        :base_image_filename,
        :vm_name,
        :mac_address,
        :bridge_adapter,
        :ram_mb,
        :hdd_gb,
        :cpu_count,
        :os_variant,
        :vnc_port,
        :vnc_ip
    )

    def initialize(input=ARGV)
        @input_arr = input

        @storage_folder = File.expand_path read_param("path", "~/vms")
        @public_key_filename = File.expand_path read_param("key", "~/.ssh/id_rsa.pub")

        _base_image_filename = read_param("img")
        if not _base_image_filename then
            _base_image_filename = ""
        else
            _base_image_filename = File.expand_path(_base_image_filename)
        end
        @base_image_filename = _base_image_filename

        @vm_name = read_param("name", "vm01")
        @mac_address = read_param("mac", "")
        @bridge_adapter = read_param("br", "br0")
        @ram_mb = read_param("ram", "1024")
        @hdd_gb = read_param("hdd", "10")
        @cpu_count = read_param("cpu", "1")
        @os_variant = read_param("os-variant", "")
        @vnc_port = read_param("vnc-port", "5900")
        @vnc_ip = read_param("vnc-ip", "0.0.0.0")
    end

    def read_param(name, default_value = nil)
        result = default_value

        idx = @input_arr.index("--#{name}")
        if idx != nil and idx >= 0 then
            result = @input_arr[idx + 1]
        end

        result
    end
end