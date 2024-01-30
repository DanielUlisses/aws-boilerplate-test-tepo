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

dependency "build_kms_key" {
  config_path  = find_in_parent_folders(local.env.build_kms_key_dependency_path)
  mock_outputs = local.env.build_kms_key_mock_output

  mock_outputs_allowed_terraform_commands = ["init", "plan", "validate", "show"]
}

terraform {
  source = "${format("tfr:///terraform-aws-modules/s3-bucket/aws?version=%s", local.version.terraform_aws_modules_s3_bucket)}"
}

inputs = {
  acl = local.inputs.acl
  bucket = coalesce(local.inputs.name_override, format("%s%s%s", local.platform.prefix, local.env.environment, local.inputs.name))
  control_object_ownership = local.inputs.control_object_ownership
  object_ownership = local.inputs.object_ownership
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = dependency.build_kms_key.outputs.key_arn
        sse_algorithm     = "aws:kms"
      }}
  }
  versioning = {
    enabled = local.inputs.versioning
  }
}
