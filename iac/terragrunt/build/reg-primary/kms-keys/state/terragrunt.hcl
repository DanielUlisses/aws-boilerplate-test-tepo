# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders("build_terragrunt.hcl")
}

# Resource groups should not be destroyed without careful consideration of effects
prevent_destroy = true

locals {
  env      = yamldecode(file(find_in_parent_folders("env.yaml")))
  inputs   = yamldecode(file("inputs.yaml"))
  platform = yamldecode(file(find_in_parent_folders("aws.yaml")))
  region   = yamldecode(file(find_in_parent_folders("region.yaml")))
  version  = yamldecode(file(find_in_parent_folders("module_versions.yaml")))
}

terraform {
  source = "${format("tfr:///terraform-aws-modules/kms/aws?version=%s", local.version.terraform_aws_modules_kms)}"
}

inputs = {
  deletion_window_in_days = local.inputs.deletion_window_in_days
}
