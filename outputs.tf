output "rocky_template_id" {
  value = data.xenorchestra_template.rocky.id
}
output "stirage_id" {
  value = data.xenorchestra_sr.storage.id
}
output "network_id" {
  value = data.xenorchestra_network.network.id
}
