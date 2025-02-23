resource "aws_instance" "pri" {
  ami                         = data.aws_ami.amazon-linux-2.id
  subnet_id                   = aws_subnet.main.id
  instance_type               = local.ec2_instance_type
  associate_public_ip_address = true
  key_name                    = aws_key_pair.v.key_name
  tags                        = local.common_tags
  iam_instance_profile        = data.aws_iam_instance_profile.instance_profile.name
  #security_groups             = ["default"]
  vpc_security_group_ids = [aws_default_security_group.default.id]
}

resource "aws_route53_record" "pri" {
  zone_id = data.aws_route53_zone.public.id
  name    = "${local.region_short}-0.${local.dns_hosted_zone_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.pri.public_ip]
}

resource "aws_instance" "sec" {
  ami                         = data.aws_ami.amazon-linux-2.id
  subnet_id                   = aws_subnet.second.id
  instance_type               = local.ec2_instance_type
  associate_public_ip_address = true
  key_name                    = aws_key_pair.v.key_name
  tags                        = local.common_tags
  iam_instance_profile        = data.aws_iam_instance_profile.instance_profile.name
  #security_groups             = ["default"]
  vpc_security_group_ids = [aws_default_security_group.default.id]
}


resource "aws_route53_record" "sec" {
  zone_id = data.aws_route53_zone.public.id
  name    = "${local.region_short}-1.${local.dns_hosted_zone_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.sec.public_ip]
}

resource "aws_elb" "w" {
  name    = "${local.region_short}-elb"
  subnets = [aws_subnet.main.id, aws_subnet.second.id]

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = aws_acm_certificate.a.arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = [aws_instance.pri.id, aws_instance.sec.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

resource "aws_route53_record" "w" {
  zone_id = data.aws_route53_zone.public.id
  name    = "west.${local.dns_hosted_zone_name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_elb.w.dns_name]
}

resource "aws_route53_health_check" "w" {
  fqdn              = aws_route53_record.w.name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
}
