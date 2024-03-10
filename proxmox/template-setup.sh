#!/bin/bash

# secure bash options
set -euf -o pipefail
trap 'echo -e "${redColor}""[ERROR] An unexpected error occured. Exiting with error!""${noColor}"' ERR

# =========================================
# VARS - adapt to your requirements
# =========================================

# provide with the image download url 
IMAGE_URL='https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img'
# give template the name you want to use
IMAGE_NAME='ubuntu-2004-cloudinit-template-test'
# set template id (number)
TEMPLATE_ID='100'
# set desired resources
CPU_CORES='1'
RAM_MEMORY='2048'
NET_ADAPTER='vmbr0'

readonly cyanColor="\e[36m"
readonly redColor="\e[31m"
readonly noColor="\e[0m"

# =========================================
# Tiny functions
# =========================================

remove_images() {
    find ./ -name "*.img" -exec rm -rf {} \;
}

get_image_name() {
    find . -name "*.img" | head -n 1 | cut -c 3-
}

is_template_there() {
    find /var/lib/vz/images/ -name "$TEMPLATE_ID"
}

# =========================================
# Main functions
# =========================================

prepare_image() {
    # remove any images first
    echo -e "${cyanColor}""[INFO] Delete all .img files""${noColor}" 
    remove_images
    
    # download image
    echo -e "${cyanColor}""[INFO] Download desired image from repository""${noColor}" 
    wget $IMAGE_URL

    image=$(get_image_name)

    if [[ -z "$image" ]]; then
        echo -e "${redColor}""[ERROR] Image not found!" "${noColor}" 
        exit 1
    else
        echo -e "${cyanColor}""[INFO] Install necessary tools""${noColor}" 
        apt update -y && sudo apt install libguestfs-tools -y

        echo -e "${cyanColor}""[INFO] Install quemu agent on freshly created image""${noColor}" 
        virt-customize -a $image --install qemu-guest-agent
    fi

    configure_template
}

configure_template() {
    # image name has been updated, lets pick it up one more time
    updated_image=$(get_image_name)

    echo -e "${cyanColor}""[INFO] Update VM with initial resources""${noColor}" 
    qm create $TEMPLATE_ID --name "$IMAGE_NAME" --memory $RAM_MEMORY --cores $CPU_CORES --net0 virtio,bridge=$NET_ADAPTER &&
    qm importdisk $TEMPLATE_ID $updated_image local &&
    qm set $TEMPLATE_ID --scsihw virtio-scsi-pci --scsi0 local:$TEMPLATE_ID/vm-$TEMPLATE_ID-disk-0.raw &&
    qm set $TEMPLATE_ID --boot c --bootdisk scsi0 &&
    qm set $TEMPLATE_ID --ide2 local:cloudinit &&
    qm set $TEMPLATE_ID --serial0 socket --vga serial0 &&
    qm set $TEMPLATE_ID --agent enabled=1
    sleep 5

    echo -e "${cyanColor}""[INFO] Converting VM into template""${noColor}" 
    qm template $TEMPLATE_ID

    template=$(is_template_there)

    if [[ -z "$template" ]]; then
        echo -e "${redColor}""[ERROR] Template not found" "${noColor}" 
        echo -e "${redColor}""[ERROR] Please recreate the template manually" "${noColor}" 
        exit 1
    else
        echo -e "${cyanColor}""[INFO] Successfully created template with ID: $TEMPLATE_ID""${noColor}" 
        echo -e "${cyanColor}""[INFO] Task complete!""${noColor}" 
    fi
}

# =========================================
# Beginning of the script
# =========================================

prepare_image
