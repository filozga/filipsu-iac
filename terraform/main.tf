terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "2.9.13"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://nsADRESSERWERA.eu:8006/api2/json"
  # api token id is in the form of: <username>@pam!<tokenId>
  # MAKE SURE TO UNCHECK "Priviledge Separation" WHEN CREATING A TOKEN IN PROXMOX UI!
  pm_api_token_id = "proxmox@pam!user-z-proxmoxa"
  pm_api_token_secret = "token-usera-z-proxmoxa"
  # leave tls_insecure set to true if you still don't use cert on Proxmox
  pm_tls_insecure = true
  # some extended logging options
  pm_log_enable = true
  # log file name created during the build
  pm_log_file = "terraform-proxmox.log"
  pm_debug = true
  pm_log_levels = {
    _default = "debug"
    _capturelog = ""
  }
}

# resource needed are "[type]" "[entity_name]"
resource "proxmox_vm_qemu" "test_server" {
  count = 1 # set to 0 and apply to destroy VM
  name = "test-vm-1"
  # this now reaches out to the vars file. I could've also used this var above in the pm_api_url setting but wanted to spell it out up there. target_node is different than api_url. target_node is which node hosts the template and thus also which node will host the new VM. it can be different than the host you use to communicate with the API. the variable contains the contents "prox-1u"
  target_node = var.proxmox_host

  # another variable with contents "ubuntu-2004-cloudinit-template"
  clone = var.template_name

  # basic VM settings here. agent refers to guest agent
  agent = 1
  os_type = "cloud-init"
  cores = 1
  sockets = 1
  cpu = "host"
  memory = 2048
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  
  # feel free to duplicate that section if more interfaces needed
  network {
    model = "virtio"
    bridge = "vmbr0"
    # vMAC generated specifically for additional IP
    macaddr = var.mac_address
  }
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  disk {
    type = "scsi"
    size = "20G"
    storage = "local"
    iothread = 0 # if changed, terraform will fail despite creating VM properly
  }

  ipconfig0 = "ip=X.X.X.X/24,gw=X.X.X.254"
  
  sshkeys = <<EOF
  ${var.ssh_key}
  EOF

  # provision configuration with Ansible
  provisioner "local-exec" {
    command = "cd ../ansible/; ANSIBLE_FORCE_COLOR=1 ansible-playbook pb-initialize.yml -i inventories/hosts -l test-vm-1 -vvv"
  }
}
