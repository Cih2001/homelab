variable "proxmox_node_name" {
  description = "Name of the proxmox node we are deploying to"
  default     = "pve01"
}

variable "k9s_control_planes" {
  description = "Specification of the control plane nodes"
  type = list(object({
    vm_id = number
    cpu = object({
      sockets = number # Number of cpu sockets
      cores   = number # Number of cpu cores
    })
    memory = number # Size of memory in MB
    disk = object({
      datastore_id = string # ID of the data store in proxmox
      size         = number # Disk size in GB
    })
    network = object({
      bridge  = string # The name of the network bridge
      vlan_id = number # The VLAN identifier.
    })
  }))

  default = [
    {
      vm_id   = 5000
      cpu     = { sockets = 1, cores = 2 }
      memory  = 4096
      disk    = { datastore_id = "local-lvm", size = 32 }
      network = { bridge = "vmbr0", vlan_id = 100 }
    },
    {
      vm_id   = 5001
      cpu     = { sockets = 1, cores = 2 }
      memory  = 4096
      disk    = { datastore_id = "local-lvm", size = 32 }
      network = { bridge = "vmbr0", vlan_id = 100 }
    }
  ]
}

variable "k9s_workers" {
  description = "Specification of the worker nodes"
  type = list(object({
    vm_id = number
    cpu = object({
      sockets = number # Number of cpu sockets
      cores   = number # Number of cpu cores
    })
    memory = number # Size of memory in MB
    disk = object({
      datastore_id = string # ID of the data store in proxmox
      size         = number # Disk size in GB
    })
    network = object({
      bridge  = string # The name of the network bridge
      vlan_id = number # The VLAN identifier.
    })
  }))

  default = [
    {
      vm_id   = 5100
      cpu     = { sockets = 2, cores = 4 }
      memory  = 8192
      disk    = { datastore_id = "local-lvm", size = 32 }
      network = { bridge = "vmbr0", vlan_id = 100 }
    },
    {
      vm_id   = 5101
      cpu     = { sockets = 2, cores = 4 }
      memory  = 8192
      disk    = { datastore_id = "local-lvm", size = 32 }
      network = { bridge = "vmbr0", vlan_id = 100 }
    },
    {
      vm_id   = 5102
      cpu     = { sockets = 2, cores = 4 }
      memory  = 8192
      disk    = { datastore_id = "local-lvm", size = 32 }
      network = { bridge = "vmbr0", vlan_id = 100 }
    },
    {
      vm_id   = 5103
      cpu     = { sockets = 2, cores = 4 }
      memory  = 8192
      disk    = { datastore_id = "local-lvm", size = 32 }
      network = { bridge = "vmbr0", vlan_id = 100 }
    },
    {
      vm_id   = 5104
      cpu     = { sockets = 2, cores = 4 }
      memory  = 8192
      disk    = { datastore_id = "local-lvm", size = 32 }
      network = { bridge = "vmbr0", vlan_id = 100 }
    }
  ]
}
