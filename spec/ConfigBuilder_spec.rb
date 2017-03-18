require "ConfigBuilder"

describe ConfigBuilder, "generate_cloud_config" do
    it "builds the cloud-config.yaml content" do
        actual = ConfigBuilder.generate_cloud_config("ssh-rsa 123ABC", "vm1")

        expect(actual).to eq(%{#cloud-config
ssh-authorized-keys:
    - ssh-rsa 123ABC
hostname: "vm1"})
    end
end