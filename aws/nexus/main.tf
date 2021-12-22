provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "http" "current_ip" {
  # url = "https://api.ipify.org/?format=json"
  url = "https://api4.my-ip.io/ip.json"
}

resource "random_id" "id" {
  byte_length = 3
}


module "environment" {
  source           = "git::https://github.com/timarenz/terraform-aws-environment.git"
  name             = "${var.environment_name}-${random_id.id.hex}"
  environment_name = var.environment_name
  owner_name       = var.owner_name
  nat_gateway      = false
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

module "nexus" {
  source                 = "git::https://github.com/timarenz/terraform-aws-virtual-machine.git"
  name                   = "${var.environment_name}-${random_id.id.hex}"
  environment_name       = var.environment_name
  owner_name             = var.owner_name
  ami_id                 = data.aws_ami.ubuntu.id
  subnet_id              = module.environment.public_subnet_ids[0]
  ssh_public_key_name    = var.ssh_public_key_name
  vpc_security_group_ids = [module.nexus_security_group.id]
  disk_size              = var.nexus_disk_size
}

module "nexus_security_group" {
  source           = "git::https://github.com/timarenz/terraform-aws-security-group.git"
  environment_name = var.environment_name
  owner_name       = var.owner_name
  name             = "${var.environment_name}-nexus-sg-${random_id.id.hex}"
  vpc_id           = module.environment.vpc_id
  ingress_rules = [{
    protocol         = "tcp"
    from_port        = "22"
    to_port          = "22"
    cidr_blocks      = ["${lookup(jsondecode(data.http.current_ip.body), "ip")}/32"]
    ipv6_cidr_blocks = null
    security_groups  = null
    prefix_list_ids  = null
    self             = true
    }, {
    protocol         = "tcp"
    from_port        = "8081"
    to_port          = "8081"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = null
    security_groups  = null
    prefix_list_ids  = null
    self             = true
    }, {
    protocol         = "tcp"
    from_port        = "8080"
    to_port          = "8080"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = null
    security_groups  = null
    prefix_list_ids  = null
    self             = true
    }, {
    protocol         = "tcp"
    from_port        = "5000"
    to_port          = "5000"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = null
    security_groups  = null
    prefix_list_ids  = null
    self             = true
    }, {
    protocol         = "-1"
    from_port        = "0"
    to_port          = "0"
    cidr_blocks      = []
    ipv6_cidr_blocks = null
    security_groups  = null
    prefix_list_ids  = null
    self             = true
  }]
}

resource "null_resource" "nexus" {
  connection {
    type = "ssh"
    host = module.nexus.public_ip
    user = "ubuntu"
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/docker.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /opt/nexus-data && sudo chown -R 200 /opt/nexus-data",
      "sudo docker run -d -p 8081:8081 -p 5000:5000 --name nexus -v /opt/nexus-data:/nexus-data sonatype/nexus3"
    ]
  }
}

module "proxy_scanner" {
  source                 = "git::https://github.com/timarenz/terraform-aws-virtual-machine.git"
  name                   = "proxy-scanner-${random_id.id.hex}"
  environment_name       = var.environment_name
  owner_name             = var.owner_name
  ami_id                 = data.aws_ami.ubuntu.id
  subnet_id              = module.environment.public_subnet_ids[0]
  ssh_public_key_name    = var.ssh_public_key_name
  vpc_security_group_ids = [module.proxy_scanner_security_group.id]
}

module "proxy_scanner_security_group" {
  source           = "git::https://github.com/timarenz/terraform-aws-security-group.git"
  environment_name = var.environment_name
  owner_name       = var.owner_name
  name             = "${var.environment_name}-proxy-scanner-sg-${random_id.id.hex}"
  vpc_id           = module.environment.vpc_id
  ingress_rules = [{
    protocol         = "tcp"
    from_port        = "22"
    to_port          = "22"
    cidr_blocks      = ["${lookup(jsondecode(data.http.current_ip.body), "ip")}/32"]
    ipv6_cidr_blocks = null
    security_groups  = null
    prefix_list_ids  = null
    self             = true
    }, {
    protocol         = "tcp"
    from_port        = "8080"
    to_port          = "8080"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = null
    security_groups  = null
    prefix_list_ids  = null
    self             = true
    }, {
    protocol         = "-1"
    from_port        = "0"
    to_port          = "0"
    cidr_blocks      = []
    ipv6_cidr_blocks = null
    security_groups  = null
    prefix_list_ids  = null
    self             = true
  }]
}

resource "null_resource" "proxy_scanner" {
  depends_on = [
    aws_lb_listener.main,
    aws_acm_certificate.nexus
  ]

  connection {
    type = "ssh"
    host = module.proxy_scanner.public_ip
    user = "ubuntu"
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/docker.sh"
  }

  provisioner "remote-exec" {
    inline = ["sudo mkdir -p /opt/proxy-scanner/cache && sudo chown -R 1000:65533 /opt/proxy-scanner/cache"]
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/config.yml.tpl", {
      account_name             = var.lacework_account_name
      integration_access_token = var.lacework_integration_access_token
      domain                   = aws_route53_record.nexus.name
      nexus_password           = var.nexus_password
    })
    destination = "/tmp/config.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/config.yml /opt/proxy-scanner/config.yml",
      "sudo docker run -d -v '/opt/proxy-scanner/cache:/opt/lacework/cache' -v '/opt/proxy-scanner/config.yml:/opt/lacework/config/config.yml' -p 8080:8080 -e LOG_LEVEL=debug --name proxy-scanner ${var.lacework_proxy_scanner_image}"
    ]
  }
}

module "alb_security_group" {
  source           = "git::https://github.com/timarenz/terraform-aws-security-group.git"
  environment_name = var.environment_name
  owner_name       = var.owner_name
  name             = "${var.environment_name}-alb-sg-${random_id.id.hex}"
  vpc_id           = module.environment.vpc_id
  ingress_rules = [{
    protocol         = "tcp"
    from_port        = "443"
    to_port          = "443"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = null
    security_groups  = null
    prefix_list_ids  = null
    self             = false
  }]
  egress_rules = [{
    protocol         = "tcp"
    from_port        = "5000"
    to_port          = "5000"
    cidr_blocks      = []
    ipv6_cidr_blocks = null
    security_groups  = [module.nexus_security_group.id]
    prefix_list_ids  = null
    self             = false
  }]
}

resource "aws_lb_listener" "main" {
  depends_on = [time_sleep.wait_for_cert]

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.nexus.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${var.environment_name}-lb-tg-${random_id.id.hex}"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = module.environment.vpc_id
  health_check {
    matcher = 400
  }
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = module.nexus.id
}


resource "aws_lb" "main" {
  name               = "${var.environment_name}-alb-${random_id.id.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.alb_security_group.id]
  subnets            = module.environment.public_subnet_ids[*]


  tags = {
    Environment = var.environment_name
    Owner       = var.owner_name
  }
}

data "aws_route53_zone" "main" {
  name = var.route53_zone_name
}

resource "aws_route53_record" "nexus" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.nexus_fqdn
  type    = "CNAME"
  ttl     = "60"
  records = [aws_lb.main.dns_name]
}

resource "aws_acm_certificate" "nexus" {
  domain_name       = aws_route53_record.nexus.name
  validation_method = "DNS"

  tags = {
    Environment = var.environment_name
    Owner       = var.owner_name
  }
}

resource "time_sleep" "wait_for_cert" {
  depends_on      = [aws_acm_certificate.nexus]
  create_duration = "30s"
}
