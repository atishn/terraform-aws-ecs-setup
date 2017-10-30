output "ecr uri for the image repositories" {
  value = {
    ecr_hub-services = "${module.ecr_hub-services.uri}"
    ecr_hub-frontend = "${module.ecr_hub-frontend.uri}"
  }
}

output "frontend urls" {
  value = {
    dev     = "http://${module.dev.hub-frontend_url}"
    qa      = "http://${module.qa.hub-frontend_url}"
    staging = "http://${module.staging.hub-frontend_url}"
    prod    = "http://${module.prod.hub-frontend_url}"
  }
}
