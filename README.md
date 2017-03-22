# kvm-automation  

Automate the creation of CoreOs and Ubuntu vms on KVM

## Prerequisites  

- ruby  
- git  
- qemu-img  
- virt-install  
- virsh  

## Usage  

Get the latest version  

```bash
git clone --depth 1 https://github.com/camilin87/kvm-automation.git
cd coreos-kvm-automation
git pull --rebase origin master
```

### Create a CoreOs vm  

```bash
ruby vm_task.rb CoreOsVmCreationTask \
    --path ~/vms/ \
    --name vm1 \
    --img ~/vm-templates/coreos_production_qemu_image.img \
    --key ~/vm-templates/id_rsa.pub \
    --mac "54:00:00:00:00:01"
```

### Create an Ubuntu vm  

```bash
ruby vm_task.rb UbuntuVmCreationTask \
    --path ~/vms/ \
    --name vm2 \
    --os-variant "ubuntu16.04" \
    --img ~/vm-templates/ubuntu-16.04.2-server-amd64.iso \
    --mac "54:00:00:00:00:02" \
    --vnc-port "5901"
# From your host vnc to `vmhost.local:5901` and finish the installation  
```

### Destroy a vm  

```bash
ruby vm_task.rb VmDeletionTask --path ~/vms/ --name vm1
```

## Dev  

### Prerequisites  

- rspec
