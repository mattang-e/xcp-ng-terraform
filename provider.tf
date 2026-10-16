terraform {
  required_providers {
    xenorchestra = {
      source = "vatesfr/xenorchestra"
    }
  }
}

provider "xenorchestra" {
  insecure = true
}