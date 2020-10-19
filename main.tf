# the account/region where CloudFront certs will live
provider "aws" {
  version = "~> 2.0"
  region = "us-east-1"
  assume_role {
    role_arn = var.deploy_role_arn
  }
  alias      = "local_account_us_east"
}

# the account/region where the environment will live
provider "aws" {
  version = "~> 2.0"
  region = var.region
  assume_role {
    role_arn = var.deploy_role_arn
  }
  alias      = "local_account_regional"
}

# the root account
provider "aws" {
  region     = "us-east-1"
  alias      = "lenovosoftware"
  access_key = var.ROOT_AWS_ACCESS_KEY
  secret_key = var.ROOT_AWS_SECRET_ACCESS_KEY
}
