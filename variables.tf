variable "vms" {
  description = "Virtual machines configuration"
  type = map(object({
    cpus       = number
    memory_gb = number
    disk_gb   = number
  }))
}