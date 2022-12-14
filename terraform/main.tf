locals {
  environment = "gh-ci"
  aws_region = "ap-northeast-1"
}

resource "random_id" "random" {
  byte_length = 20
}

module "github-runner" {
  source  = "philips-labs/github-runner/aws"
  version = "1.12.0"

  create_service_linked_role_spot = true
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
  # enable_organization_runners = true
  runner_extra_labels = "aws"
  log_level = "debug"
  runner_enable_workflow_job_labels_check = true

  enable_ssm_on_runners = true

  instance_types = ["t3a.medium"]

  # override delay of events in seconds
  delay_webhook_event   = 5
  runners_maximum_count = 2

  runner_run_as = "ubuntu"

  # AMI selection and userdata
  #
  # option 1. configure your pre-built AMI + userdata
  userdata_template = "./templates/user-data.sh"
  ami_owners        = ["099720109477"] # Canonical's Amazon account ID

  ami_filter = {
    name = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  block_device_mappings = [{
    # Set the block device name for Ubuntu root device
    device_name           = "/dev/sda1"
    delete_on_termination = true
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    iops                  = null
    throughput            = null
    kms_key_id            = null
    snapshot_id           = null
  }]

  runner_log_files = [
    {
      "log_group_name" : "syslog",
      "prefix_log_group" : true,
      "file_path" : "/var/log/syslog",
      "log_stream_name" : "{instance_id}"
    },
    {
      "log_group_name" : "user_data",
      "prefix_log_group" : true,
      "file_path" : "/var/log/user-data.log",
      "log_stream_name" : "{instance_id}/user_data"
    },
    {
      "log_group_name" : "runner",
      "prefix_log_group" : true,
      "file_path" : "/opt/actions-runner/_diag/Runner_**.log",
      "log_stream_name" : "{instance_id}/runner"
    }
  ]

  idle_config = [
    {
      cron      = "* * 20-23 * * 1-5"
      timeZone  = "Asia/Tokyo"
      idleCount = 1
    }
  ]
}