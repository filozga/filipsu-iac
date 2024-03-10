variable "ssh_key" {
    default = "wrzuc tu ten sam klucz publiczny"
}
variable "proxmox_host" {
    default = "suavity"
}

variable "template_name" {
    default = "ubuntu-2004-cloudinit-template"
}

variable "template_id" {
    default = "100"
}

variable "mac_address" {
    default = "MAC dla IP FO"
}

variable "ansible_path" {
    default = "../ansible/"
}