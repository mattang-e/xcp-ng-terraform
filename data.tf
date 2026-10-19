data "xenorchestra_template" "rocky" {
  name_label = "rocky9-template"
}

data "xenorchestra_sr" "storage" {
  name_label = "main_storage"
}

data "xenorchestra_network" "network" {
  name_label = "vlan10"
}