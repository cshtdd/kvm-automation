# coreos-kvm-automation  

Automate the creation of CoreOs vms on KVM

## Prerequisites  

- ruby  
- git  
- qemu-img  

## Usage  

Get the latest version  

```bash
git clone --depth 1 https://github.com/camilin87/coreos-kvm-automation.git
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

### Destroy a vm  

```bash
ruby vm_task.rb VmDeletionTask \
    --path ~/vms/ \
    --name vm1
```

## Dev  

### Prerequisites  

- rspec
