# kvm-automation  

Automate the creation of CoreOs and Ubuntu vms on KVM

## Prerequisites  

- ruby  
- git  
- qemu-img  
- virt-install  
- virsh  
- wget  
- bzip2  
- dd  
- gzip  
- perl  
- libxml-simple-perl  
- libsys-virt-perl  


Configure the virtualization host [following these steps](https://www.cyberciti.biz/faq/installing-kvm-on-ubuntu-16-04-lts-server/)  

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
    --key ~/vm-templates/id_rsa.pub
```

### Create an Ubuntu vm  

```bash
ruby vm_task.rb UbuntuVmCreationTask \
    --path ~/vms/ \
    --name vm2 \
    --os-variant "ubuntu16.04" \
    --img ~/vm-templates/ubuntu-16.04.2-server-amd64.iso
# At this point the command will display the vm's mac address and vnc port  
# From your host vnc to `vmhost.local:<VNC_PORT>` and finish the installation  
```

### Restore an Ubuntu vm  

```bash
ruby vm_task.rb UbuntuVmRestoreTask \
    --path ~/vms/ \
    --name vm3 \
    --os-variant "ubuntu16.04" \
    --img ~/vm-backups/vm1/vm1_vda.img.gz
```

### Backup a vm  

```bash
sudo ruby vm_task.rb VmBackupTask --path ~/vm-backups/ --name vm1
```

### Destroy a vm  

```bash
ruby vm_task.rb VmDeletionTask --path ~/vms/ --name vm1
```

### Get the mac address of a vm  

```bash
ruby vm_task.rb ReadVmMacTask --name vm1
```

### Get the vnc infomation of a vm  

```bash
ruby vm_task.rb ReadVmVncInfoTask --name vm1
```
