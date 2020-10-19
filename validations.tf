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
