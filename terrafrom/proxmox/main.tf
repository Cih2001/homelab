provider "proxmox" {
  endpoint = "https://pve01.geekembly.com:8006/"
  insecure = true
  ssh {
    agent = true
  }
}

resource "proxmox_virtual_environment_vm" "k8s-controlplane" {
  for_each = { for _, cp in var.k9s_control_planes :
    cp.vm_id => cp
  }
  name        = "k8s-cp-${format("%02d", each.key + 1)}"
  description = "kubernetes control plane node ${each.key + 1}"
  tags        = ["terraform", "debian", "k8s-cp"]
  node_name   = var.proxmox_node_name
  vm_id       = each.value.vm_id

  agent {
    enabled = true
  }

  cpu {
    cores   = each.value.cpu.cores
    sockets = each.value.cpu.sockets
    type    = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = each.value.disk.datastore_id
    file_id      = proxmox_virtual_environment_download_file.latest_debian_12_bookworm_qcow2_img.id
    interface    = "virtio0"
    iothread     = true
    size         = each.value.disk.size
  }

  network_device {
    bridge  = each.value.network.bridge
    vlan_id = each.value.network.vlan_id
    model   = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }
}


resource "proxmox_virtual_environment_vm" "k8s-worker" {
  for_each = { for _, cp in var.k9s_workers :
    cp.vm_id => cp
  }
  name        = "k8s-wk-${format("%02d", each.key + 1)}"
  description = "kubernetes worker node ${each.key + 1}"
  tags        = ["terraform", "debian", "k8s-wk"]
  node_name   = var.proxmox_node_name
  vm_id       = each.value.vm_id

  agent {
    enabled = true
  }

  cpu {
    cores   = each.value.cpu.cores
    sockets = each.value.cpu.sockets
    type    = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = each.value.disk.datastore_id
    file_id      = proxmox_virtual_environment_download_file.latest_debian_12_bookworm_qcow2_img.id
    interface    = "virtio0"
    iothread     = true
    size         = each.value.disk.size
  }

  network_device {
    bridge  = each.value.network.bridge
    vlan_id = each.value.network.vlan_id
    model   = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }
}

output "workers_IPv4" {
  value = [
    for vm in proxmox_virtual_environment_vm.k8s-worker : vm.ipv4_addresses[1][0]
  ]
}

output "control_planes_IPv4" {
  value = [
    for vm in proxmox_virtual_environment_vm.k8s-controlplane : vm.ipv4_addresses[1][0]
  ]
}
