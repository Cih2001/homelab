locals {
  cp_ips = [
    for vm in proxmox_virtual_environment_vm.k8s-controlplane : vm.ipv4_addresses[1][0]
  ]

  worker_ips = [
    for vm in proxmox_virtual_environment_vm.k8s-worker : vm.ipv4_addresses[1][0]
  ]
}

resource "local_file" "ansible_inventory" {
  filename = "../../ansible/inventory.ini"
  content = templatefile("${path.module}/inventory_template.tpl", {
    cp_count     = length(var.k9s_control_planes)
    worker_count = length(var.k9s_workers)
    cp_ips       = local.cp_ips
    worker_ips   = local.worker_ips
  })

  # provisioner "local-exec" {
  #   command     = "ansible-playbook -i inventory.ini -e @cluster_variables.yaml --user=ansible playbook.yml"
  #   working_dir = "../ansible"
  #   environment = {
  #     ANSIBLE_HOST_KEY_CHECKING = "false"
  #   }
  # }
}
