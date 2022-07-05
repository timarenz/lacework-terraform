provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "http" "current_ip" {
  url = "https://api4.my-ip.io/ip.json"
}

resource "random_id" "id" {
  byte_length = 3
}

resource "aws_ecr_repository" "main" {
  name                 = "${var.environment_name}-${random_id.id.hex}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Environment = var.environment_name
    Owner       = var.owner_name
  }
}

resource "aws_iam_instance_profile" "proxy_scanner" {
  name = "${var.environment_name}-${random_id.id.hex}-proxy-scanner"
  role = aws_iam_role.proxy_scanner.name
}

resource "aws_iam_role" "proxy_scanner" {
  name               = "${var.environment_name}-${random_id.id.hex}-proxy-scaner"
  assume_role_policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "sts:AssumeRole",
                "Principal": {
                  "Service": "ec2.amazonaws.com"
                },
                "Effect": "Allow"
            }
        ]
    }
    EOF
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.proxy_scanner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


module "aws" {
  source           = "git::https://github.com/timarenz/terraform-aws-environment.git?ref=v0.1.2"
  environment_name = var.environment_name
  owner_name       = var.owner_name
  nat_gateway      = false
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "ssh" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.root}/ssh.key"
  file_permission = "0400"
}

resource "aws_key_pair" "ssh" {
  key_name   = "${var.owner_name}-${var.environment_name}"
  public_key = tls_private_key.ssh.public_key_openssh
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


resource "aws_security_group" "egress" {
  name   = "${var.environment_name}-egress"
  vpc_id = module.aws.vpc_id

  egress {
    protocol         = "-1"
    from_port        = "0"
    to_port          = "0"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    environment = var.environment_name
    owner       = var.owner_name
  }
}

resource "aws_security_group" "ssh" {
  name   = "${var.environment_name}-ssh"
  vpc_id = module.aws.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = "22"
    to_port     = "22"
    cidr_blocks = ["${lookup(jsondecode(data.http.current_ip.body), "ip")}/32"]
    self        = true
  }

  tags = {
    environment = var.environment_name
    owner       = var.owner_name
  }
}

resource "random_shuffle" "subnet" {
  input        = module.aws.public_subnet_ids
  result_count = 1
}

resource "aws_instance" "proxy_scanner" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  subnet_id                   = random_shuffle.subnet.result[0]
  vpc_security_group_ids      = [aws_security_group.egress.id, aws_security_group.ssh.id]
  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.proxy_scanner.name

  root_block_device {
    volume_type = "gp2"
    volume_size = 16
  }

  tags = {
    environment = var.environment_name
    owner       = var.owner_name
    Name        = "${var.environment_name}-vm"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/docker.sh"
  }

  provisioner "remote-exec" {
    inline = ["sudo mkdir -p /opt/proxy-scanner/cache && sudo chown -R 1000:65533 /opt/proxy-scanner/cache"]
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/config.ini.tpl", {
      role_arn = aws_iam_role.proxy_scanner.arn
    })
    destination = "/tmp/config.ini"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/config.yml.tpl", {
      lacework_account_name             = var.lacework_account_name
      lacework_integration_access_token = var.lacework_integration_access_token
      ecr_domain                        = element(split("/", aws_ecr_repository.main.repository_url), 0)
    })
    destination = "/tmp/config.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/config.ini /opt/proxy-scanner/config.ini",
      "sudo mv /tmp/config.yml /opt/proxy-scanner/config.yml",
      "sudo docker run -d -v '/opt/proxy-scanner/cache:/opt/lacework/cache' -v '/opt/proxy-scanner/config.yml:/opt/lacework/config/config.yml' -v '/opt/proxy-scanner/config.ini:/home/.aws/config' -p 8080:8080 -e LOG_LEVEL=debug --name proxy-scanner ${var.lacework_proxy_scanner_image}"
    ]
  }
}

