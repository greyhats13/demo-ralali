resource "aws_security_group" "bastion-sg" {
  name        = "bastion-sg"
  description = "kubectl_instance_sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-security-group"
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "deployer-key"
  public_key = tls_private_key.this.public_key_openssh
}

resource "aws_instance" "bastion" {
  count                  = length(var.public_subnet)
  instance_type          = var.instance_type
  ami                    = var.instance_ami
  key_name               = aws_key_pair.this.key_name
  subnet_id              = element(var.public_subnet, count.index)
  vpc_security_group_ids = [aws_security_group.bastion-sg.id]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "20"
    delete_on_termination = "true"
  }

  tags = {
    Name = var.server_name
  }
}
