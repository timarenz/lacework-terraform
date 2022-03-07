provider "aws" {
  region = var.aws_region
}

provider "lacework" {
  profile = var.profile
}

data "lacework_agent_access_token" "nomad" {
  name = var.lacework_agent_token_name
}

data "http" "current_ip" {
  # url = "https://api.ipify.org/?format=json"
  url = "https://api4.my-ip.io/ip.json"
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
  key_name   = "${var.environment_name}-${var.owner_name}-ssh"
  public_key = tls_private_key.ssh.public_key_openssh
}

module "aws" {
  source           = "git::https://github.com/timarenz/terraform-aws-environment.git?ref=v0.1.2"
  environment_name = var.environment_name
  owner_name       = var.owner_name
  nat_gateway      = false
}

module "nomad_security_group" {
  source           = "git::https://github.com/timarenz/terraform-aws-security-group.git?ref=v0.1.0"
  environment_name = var.environment_name
  owner_name       = var.owner_name
  name             = "${var.environment_name}-sg"
  vpc_id           = module.aws.vpc_id
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
    from_port        = "80"
    to_port          = "80"
    cidr_blocks      = ["${lookup(jsondecode(data.http.current_ip.body), "ip")}/32"]
    ipv6_cidr_blocks = null
    security_groups  = null
    prefix_list_ids  = null
    self             = true
    }, {
    protocol         = "tcp"
    from_port        = "5001"
    to_port          = "5001"
    cidr_blocks      = ["${lookup(jsondecode(data.http.current_ip.body), "ip")}/32"]
    ipv6_cidr_blocks = null
    security_groups  = null
    prefix_list_ids  = null
    self             = true
    }, {
    protocol         = "tcp"
    from_port        = "4646"
    to_port          = "4646"
    cidr_blocks      = ["${lookup(jsondecode(data.http.current_ip.body), "ip")}/32"]
    ipv6_cidr_blocks = null
    security_groups  = null
    prefix_list_ids  = null
    self             = true
    }, {
    protocol         = "tcp"
    from_port        = "8500"
    to_port          = "8500"
    cidr_blocks      = ["${lookup(jsondecode(data.http.current_ip.body), "ip")}/32"]
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

module "nomad_iam_instance_profile" {
  source           = "git::https://github.com/timarenz/terraform-aws-iam-instance-profile.git?ref=v0.1.0"
  environment_name = var.environment_name
  owner_name       = var.owner_name
  name             = "${var.environment_name}-iam-instance-profile"
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

module "nomad_server" {
  count                  = var.nomad_server_count
  source                 = "git::https://github.com/timarenz/terraform-aws-virtual-machine.git?ref=v0.2.2"
  environment_name       = var.environment_name
  owner_name             = var.owner_name
  ami_id                 = data.aws_ami.ubuntu.id
  name                   = "${var.environment_name}-server-${count.index}"
  subnet_id              = element(module.aws.public_subnet_ids, count.index)
  ssh_public_key_name    = aws_key_pair.ssh.key_name
  vpc_security_group_ids = [module.nomad_security_group.id]
  iam_instance_profile   = module.nomad_iam_instance_profile.instance_profile_id
  tags = {
    "${var.environment_name}" = "server"
  }
}

resource "null_resource" "nomad_server" {
  count = var.nomad_server_count

  connection {
    type        = "ssh"
    host        = module.nomad_server[count.index].public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/consul-server.hcl", {
      server_count = var.nomad_server_count
      retry_join   = "provider=aws tag_key=${var.environment_name} tag_value=server region=${var.aws_region}"
    })
    destination = "/tmp/consul.hcl"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/nomad-server.hcl", {
      server_count = var.nomad_server_count
      retry_join   = "provider=aws tag_key=${var.environment_name} tag_value=server region=${var.aws_region}"
    })
    destination = "/tmp/nomad.hcl"
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/prereqs.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sSL https://s3-us-west-2.amazonaws.com/www.lacework.net/download/4.3.0.5556_2021-10-04_release-v4.3_c4bb0ab95f6129749e61be26afb4b9d503c11522/install.sh > /tmp/lw-install.sh",
      "chmod +x /tmp/lw-install.sh",
      "sudo /tmp/lw-install.sh -U ${var.lw_apiurl} ${data.lacework_agent_access_token.nomad.token}",
      "rm -rf /tmp/lw-install.sh"
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/docker.sh",
      "${path.module}/scripts/consul.sh",
      "${path.module}/scripts/consul-dns.sh",
      "${path.module}/scripts/nomad.sh"
    ]
  }
}

module "nomad_client" {
  count                  = var.nomad_client_count
  source                 = "git::https://github.com/timarenz/terraform-aws-virtual-machine.git?ref=v0.2.2"
  environment_name       = var.environment_name
  owner_name             = var.owner_name
  ami_id                 = data.aws_ami.ubuntu.id
  name                   = "${var.environment_name}-client-${count.index}"
  ssh_public_key_name    = aws_key_pair.ssh.key_name
  subnet_id              = element(module.aws.public_subnet_ids, count.index)
  vpc_security_group_ids = [module.nomad_security_group.id]
  iam_instance_profile   = module.nomad_iam_instance_profile.instance_profile_id
}

resource "null_resource" "nomad_client" {
  count = var.nomad_client_count

  connection {
    type        = "ssh"
    host        = module.nomad_client[count.index].public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/consul-client.hcl", {
      retry_join = "provider=aws tag_key=${var.environment_name} tag_value=server region=${var.aws_region}"
    })
    destination = "/tmp/consul.hcl"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/nomad-client.hcl", {
      retry_join = "provider=aws tag_key=${var.environment_name} tag_value=server region=${var.aws_region}"
      app_type   = element(["ui", "data", "worker"], count.index)
    })
    destination = "/tmp/nomad.hcl"
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/prereqs.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sSL https://s3-us-west-2.amazonaws.com/www.lacework.net/download/4.3.0.5556_2021-10-04_release-v4.3_c4bb0ab95f6129749e61be26afb4b9d503c11522/install.sh > /tmp/lw-install.sh",
      "chmod +x /tmp/lw-install.sh",
      "sudo /tmp/lw-install.sh -U ${var.lw_apiurl} ${data.lacework_agent_access_token.nomad.token}",
      "rm -rf /tmp/lw-install.sh"
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/docker.sh",
      "${path.module}/scripts/consul.sh",
      "${path.module}/scripts/consul-dns.sh",
      "${path.module}/scripts/nomad.sh"
    ]
  }
}
