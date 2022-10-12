locals {
  environment = "gh-ci"
  aws_region = "ap-northeast-1"
}

resource "random_id" "random" {
  byte_length = 20
}

module "github-runner" {
  source  = "philips-labs/github-runner/aws"
  version = "1.11.0"

  aws_region = local.aws_region
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets

  prefix = local.environment

  github_app = {
    key_base64     = var.github_app_key_base64
    id             = var.github_app_id
    webhook_secret = random_id.random.hex
  }

  webhook_lambda_zip                = "lambdas-download/webhook.zip"
  runner_binaries_syncer_lambda_zip = "lambdas-download/runner-binaries-syncer.zip"
  runners_lambda_zip                = "lambdas-download/runners.zip"
  enable_organization_runners = true
  instance_types = ["t4g.medium"]
}