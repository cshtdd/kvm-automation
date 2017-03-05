class ConfigBuilder
    def self.generate_cloud_config(rsa_public_key, vm_name)
        %{
hostname: "#{vm_name}"
ssh-authorized-keys:
    - #{rsa_public_key}
}
    end
end