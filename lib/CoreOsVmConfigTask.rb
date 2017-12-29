require_relative "VmTask"

class CoreOsVmConfigTask < VmTask
  def run_with(vm_manager)
    vm_manager.generate_vm_config_drive @config.public_key_filename
  end
end