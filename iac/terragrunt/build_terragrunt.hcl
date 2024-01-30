# configure azure bucket dynamically.
remote_state {
  backend = "s3"
  config = {
    bucket         = format("%s%stfstate", local.platform.prefix, local.env.environment)
    dynamodb_table = format("%s%stfstate", local.platform.prefix, local.env.environment)
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region.region
  }
}

locals {
  platform          = yamldecode(file("build/aws.yaml"))
  env               = yamldecode(file("build/env.yaml"))
  conf              = yamldecode(file("build/terragrunt_conf.yaml"))
  region            = yamldecode(file("build/reg-primary/region.yaml"))
}

terragrunt_version_constraint = local.conf.terragrunt_required_version
terraform_version_constraint  = local.conf.terraform_required_version

generate "provider" {
  path      = "provider_override.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${format("~> %s", local.conf.aws_provider_version)}"
    }
  }
}

provider "aws" {
  region = "${local.region.region}"
}
EOF
}
