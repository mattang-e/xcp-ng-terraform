data "xenorchestra_template" "rocky" {
  name_label = "rocky9-template"
}

data "xenorchestra_sr" "storage" {
  name_label = "main_storage"
}

data "xenorchestra_network" "network" {
  name_label = "vlan10"
}

resource "xenorchestra_vm" "vm" {
  for_each = var.vms

  name_label = each.key

  template   = data.xenorchestra_template.rocky.id
  cpus       = each.value.cpus
  memory_max = each.value.memory_gb * 1024 * 1024 * 1024

  network {
    network_id = data.xenorchestra_network.network.id
  }
  disk {
    sr_id      = data.xenorchestra_sr.storage.id
    name_label = "${each.key}-disk"
    size       = each.value.disk_gb * 1024 * 1024 * 1024
  }
}