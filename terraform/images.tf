resource "proxmox_virtual_environment_download_file" "latest_debian_12_bookworm_qcow2_img" {
  content_type        = "iso"
  datastore_id        = "local"
  file_name           = "debian-12-generic-amd64.img"
  node_name           = var.proxmox_node_name
  url                 = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  overwrite           = true
  overwrite_unmanaged = true
  checksum_algorithm  = "sha512"
  checksum            = "f7ac3fb9d45cdee99b25ce41c3a0322c0555d4f82d967b57b3167fce878bde09590515052c5193a1c6d69978c9fe1683338b4d93e070b5b3d04e99be00018f25"
}

data "local_file" "ssh_public_key" {
  filename = "./id_rsa.pub"
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name

  source_raw {
    data = <<-EOF
    #cloud-config
    users:
      - name: root
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
      - name: ansible
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    runcmd:
        - apt update
        - apt install -y qemu-guest-agent net-tools
        - timedatectl set-timezone America/Toronto
        - systemctl enable qemu-guest-agent
        - systemctl start qemu-guest-agent
        - echo "done" > /tmp/cloud-config.done
  EOF

    file_name = "cloud-config.yaml"
  }
}
