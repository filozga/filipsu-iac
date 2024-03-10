# suavity-infra
Infrastructure as a code setup for Suavity Private Cloud based on Proxmox

## Tools and requirements

### Proxmox
* Root access to Proxmox host via ssh
* Additional IPs for VM network bridging
* Technical user, with full amdin role and API token

### Terraform
Something

## Ansible
1) Install ansible locally or on a separate server
```apt install ansible```

2) Install necessary collections
```ansible-galaxy collection install ansible.posix```
