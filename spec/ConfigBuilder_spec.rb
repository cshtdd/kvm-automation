require 'ConfigBuilder'

describe 'ConfigBuilder' do
    it 'builds the cloud-config.yaml content' do
        actual = ConfigBuilder.generate_cloud_config('ssh-rsa 123ABC', 'vm1')

        expect(actual).to eq(%{
hostname: "vm1"
ssh-authorized-keys:
    - ssh-rsa 123ABC
})
    end
end