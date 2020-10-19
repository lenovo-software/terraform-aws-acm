data "aws_route53_zone" "default" {
  name         = var.hosted_zone
  private_zone = false
  provider = aws.lenovosoftware
}