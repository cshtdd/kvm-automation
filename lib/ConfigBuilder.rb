class ConfigBuilder
    def self.generate_cloud_config(rsa_public_key, vm_name)
        %{#cloud-config
ssh-authorized-keys:
    - #{rsa_public_key}}
    end
end