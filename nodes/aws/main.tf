provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  region = var.aws_region
}

# Data source para obtener el VPC por defecto
data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "exit-node" {
  ami           = var.ami_id
  instance_type = "t3.medium"
  key_name      = "proxycannon"
  vpc_security_group_ids = [aws_security_group.exit-node-sec-group.id]
  subnet_id     = var.subnet_id
  # we need to disable this for internal routing
  source_dest_check = false
  count = var.instance_count

  tags = {
    Name = "exit-node-${count.index + 1}"
  }

  # upload our provisioning scripts
  provisioner "file" {
    source      = "${path.module}/configs/"
    destination = "/tmp/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.aws_priv_key)
      host        = self.public_ip
    }
  }

  # execute our provisioning scripts
  provisioner "remote-exec" {
    script = "${path.module}/configs/node_setup.bash"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.aws_priv_key)
      host        = self.public_ip
    }
  }

  # modify our route table when we bring up an exit-node
  provisioner "local-exec" {
    command = "sudo ${path.module}/add_route.bash ${self.private_ip}"
  }

  # modify our route table when we destroy an exit-node
  provisioner "local-exec" {
    when    = destroy
    command = "sudo ${path.module}/del_route.bash ${self.private_ip}"
  }
}

resource "aws_security_group" "exit-node-sec-group" {
  name_prefix = "exit-node-sec-group-"
  description = "Security group for exit nodes"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "exit-node-security-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}