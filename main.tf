provider "aws" {
  region     = "us-east-1"
  alias      = "lenovosoftware"
  access_key = var.ROOT_AWS_ACCESS_KEY
  secret_key = var.ROOT_AWS_SECRET_ACCESS_KEY
}

# the account where the environment will live
provider "aws" {
  version = "~> 2.0"
  region = "us-east-1"
  assume_role {
    role_arn = var.deploy_role_arn
  }
  alias      = "local_account_us_east"
}

# the account where the environment will live
provider "aws" {
  version = "~> 2.0"
  region = "us-east-1"
  assume_role {
    role_arn = var.deploy_role_arn
  }
  alias      = "local_account_regional"
}


locals {
  // Get distinct list of domains and SANs
  distinct_domain_names = distinct(concat([var.domain_name], [for s in var.subject_alternative_names : replace(s, "*.", "")]))

  // Copy domain_validation_options for the distinct domain names
  validation_domains = var.create_certificate ? [for k, v in aws_acm_certificate.this[0].domain_validation_options : tomap(v) if contains(local.distinct_domain_names, replace(v.domain_name, "*.", ""))] : []
}

resource "aws_acm_certificate" "this" {
  count = var.create_certificate ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method

  options {
    certificate_transparency_logging_preference = var.certificate_transparency_logging_preference ? "ENABLED" : "DISABLED"
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }

  provider = aws.local_account_us_east
}

resource "aws_route53_record" "validation" {
  count = var.create_certificate && var.validation_method == "DNS" && var.validate_certificate ? length(local.distinct_domain_names) + 1 : 0

  zone_id = var.zone_id
  name    = element(local.validation_domains, count.index)["resource_record_name"]
  type    = element(local.validation_domains, count.index)["resource_record_type"]
  ttl     = var.dns_ttl

  records = [
    element(local.validation_domains, count.index)["resource_record_value"]
  ]

  allow_overwrite = var.validation_allow_overwrite_records

  depends_on = [aws_acm_certificate.this]

  provider = aws.lenovosoftware
}

resource "aws_acm_certificate_validation" "this" {
  count = var.create_certificate && var.validation_method == "DNS" && var.validate_certificate && var.wait_for_validation ? 1 : 0

  certificate_arn = aws_acm_certificate.this[0].arn

  validation_record_fqdns = aws_route53_record.validation.*.fqdn

  provider = aws.lenovosoftware
}

#############################
# MUTLI REGION SUPPORT
#############################

resource "aws_acm_certificate" "region_this" {
  count = var.create_certificate  && !var.in_us_east ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method

  options {
    certificate_transparency_logging_preference = var.certificate_transparency_logging_preference ? "ENABLED" : "DISABLED"
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }

  provider = aws.local_account_regional
}

resource "aws_route53_record" "region_validation" {
  count = var.create_certificate && var.validation_method == "DNS" && var.validate_certificate && !var.in_us_east ? length(local.distinct_domain_names) + 1 : 0

  zone_id = var.zone_id
  name    = element(local.validation_domains, count.index)["resource_record_name"]
  type    = element(local.validation_domains, count.index)["resource_record_type"]
  ttl     = var.dns_ttl

  records = [
    element(local.validation_domains, count.index)["resource_record_value"]
  ]

  allow_overwrite = var.validation_allow_overwrite_records

  depends_on = [aws_acm_certificate.region_this]

  provider = aws.lenovosoftware
}

resource "aws_acm_certificate_validation" "region_this" {
  count = var.create_certificate && var.validation_method == "DNS" && var.validate_certificate && var.wait_for_validation && !var.in_us_east ? 1 : 0

  certificate_arn = aws_acm_certificate.region_this[0].arn

  validation_record_fqdns = aws_route53_record.region_validation.*.fqdn

  provider = aws.lenovosoftware
}
