# Proxmox

## Create your VM template for further provisioning

### Create Ubuntu template with script

1. Login directly to Proxmox host via ssh
2. Clone this repo
3. Execute bash script*
```bash suavity-infra/proxmox/template-setup.sh```

*optionally reproduce all steps manually as shown below:

### Create any template manually

1) Look for desired resource: https://cloud-images.ubuntu.com/
```wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img```

2) Install necessary tools
```apt update -y && sudo apt install libguestfs-tools -y```

3) install quemu agent on freshly created image\
```virt-customize -a focal-server-cloudimg-amd64.img --install qemu-guest-agent```

### Define setup for a new VM template

1) set template name and pecify resources
```qm create 100 --name "ubuntu-2004-cloudinit-template" --memory 2048 --cores 1 --net0 virtio,bridge=vmbr0```

2) import image to storage
```qm importdisk 100 focal-server-cloudimg-amd64.img local```

3) set the disk used by image
```qm set 100 --scsihw virtio-scsi-pci --scsi0 local:100/vm-100-disk-0.raw```

4) set booting drive\
```qm set 100 --boot c --bootdisk scsi0```

5) set cloud-init
```qm set 100 --ide2 local:cloudinit```

6) define virtual serial port
```qm set 100 --serial0 socket --vga serial0```

7) enable quemu agent
```qm set 100 --agent enabled=1```

8) convert VM into template
```qm template 100```

### Create new VM based on template - already managed by Terraform

1) create new VM 
```qm clone 100 900 --name test-clone-cloud-init```

2) publish ssh key into new VM
```qm set 900 --sshkey technic.pub```

3) configure main network interface - here bridging of additional IP address
```qm set 900 --ipconfig0 ip=X.X.X.X/32,gw=X.X.X.254```

4) run VM
```qm start 900```
