class TaskConfig
    def initialize(input=ARGV)
        @input_arr = input

        @storage_folder = read_parameter_value "path"
        @public_key_filename = read_parameter_value "key"
        @base_image_filename = read_parameter_value "img"
        @vm_name = read_parameter_value "name"
        @mac_address = read_parameter_value "mac"
        @bridge_adapter = read_parameter_value "br"
        @ram_mb = read_parameter_value "ram"
        @cpu_count = read_parameter_value "cpu"
    end

    def read_parameter_value(name)
        result = nil

        idx = @input_arr.index("--#{name}")
        if idx != nil and idx >= 0 then
            result = @input_arr[idx + 1]
        end

        result
    end

    def storage_folder
        File.expand_path(@storage_folder || "~/vms")
    end

    def public_key_filename
        File.expand_path(@public_key_filename || "~/.ssh/id_rsa.pub")
    end

    def base_image_filename
        if not @base_image_filename then
            return ""
        end

        File.expand_path(@base_image_filename)
    end

    def vm_name
        @vm_name || "vm01"
    end

    def mac_address
        @mac_address || "54:36:E2:84:5A:C0"
    end

    def bridge_adapter
        @bridge_adapter || "br0"
    end

    def ram_mb
        @ram_mb || "1024"
    end

    def cpu_count
        @cpu_count || "1"
    end
end