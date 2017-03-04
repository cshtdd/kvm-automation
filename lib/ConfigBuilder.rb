class ConfigBuilder
    def self.generate_cloud_config(public_rsa_key, vm_name)
        %{
hostname: "#{vm_name}"
ssh-authorized-keys:
    - #{public_rsa_key}
}
    end
end