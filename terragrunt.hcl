terraform {
  source = "tfr:///terraform-aws-modules/ec2-instance/aws?version=4.0.0"
}

locals {
  # Use environment variable to simulate workspaces
  workspace = get_env("TG_WORKSPACE", "default")

  # Define configurations for each workspace (environment)
  configs = {
    dev = {
      bucket         = "terragrunt-bucket-dev-123"
      instance_type  = "t2.micro"
      state_key      = "dev/ec2-instance/terraform.tfstate"
      tags           = { Name = "Dev Terragrunt -- EC2" }
    }
    test = {
      bucket         = "terragrunt-bucket-test-123"
      instance_type  = "t2.small"
      state_key      = "test/ec2-instance/terraform.tfstate"
      tags           = { Name = "Test Terragrunt -- EC2" }
    }
  }

  # Dynamically select the config for the current workspace
  current_config = local.configs[local.workspace]
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  profile = "sandbox"
  region  = "eu-central-1"
  shared_credentials_files = ["/C:/Users/yth/.aws/credentials"]
}
EOF
}

inputs = {
  ami           = "ami-0767046d1677be5a0"
  instance_type = local.current_config.instance_type
  tags          = local.current_config.tags
}

remote_state {
  backend = "s3"
  config = {
    bucket = local.current_config.bucket
    region = "eu-central-1"
    key    = local.current_config.state_key
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
