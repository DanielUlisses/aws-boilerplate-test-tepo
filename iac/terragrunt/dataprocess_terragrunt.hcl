# configure azure bucket dynamically.
remote_state {
  backend = "s3"
  config = {
    bucket         = format("%s%stfstate", local.platform.prefix, local.env.environment)
    dynamodb_table = format("%s%stfstate", local.platform.prefix, local.env.environment)
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:555091451601:key/9fd6fdf9-4dbf-4820-8852-1137c1f0c3aa"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region.region
  }
}

locals {
  platform          = yamldecode(file("dataprocess/aws.yaml"))
  env               = yamldecode(file("dataprocess/env.yaml"))
  conf              = yamldecode(file("dataprocess/terragrunt_conf.yaml"))
  region            = yamldecode(file("dataprocess/reg-primary/region.yaml"))
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
