class TaskConfig
    def initialize(input=ARGV)
        @input_arr = input
    end

    def storage_folder
        @storage_folder || File.expand_path("~/vms")
    end

    def public_key_filename
        @public_key_filename || File.expand_path("~/.ssh/id_rsa.pub")
    end

    def base_image_filename
        @base_image_filename || ""
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