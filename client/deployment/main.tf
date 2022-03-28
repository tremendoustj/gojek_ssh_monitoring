# ---------------------------------------------------------------------------------------------------------------------
# PIN TERRAFORM VERSION TO >= 0.12
# The examples have been upgraded to 0.12 syntax
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 0.13.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.13.x code.
  required_version = ">= 0.12.26"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY AN INSTANCE, THEN TRIGGER A PROVISIONER
# See test/terraform_ssh_example.go for how to write automated tests for this code.
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE EC2 INSTANCE WITH A PUBLIC IP
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "example_public" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.example.id]
  key_name               = var.key_pair_name

  # This EC2 Instance has a public IP and will be accessible directly from the public Internet
  associate_public_ip_address = true

  tags = {
    Name = "${var.instance_name}-public"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO CONTROL WHAT REQUESTS CAN GO IN AND OUT OF THE EC2 INSTANCES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "example" {
  name = var.instance_name

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = var.ssh_port
    to_port   = var.ssh_port
    protocol  = "tcp"

    # To keep this example simple, we allow incoming SSH requests from any IP. In real-world usage, you should only
    # allow SSH requests from trusted servers, such as a bastion host or VPN server.
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = var.http_port
    to_port   = var.http_port
    protocol  = "tcp"

    # To keep this example simple, we allow incoming SSH requests from any IP. In real-world usage, you should only
    # allow SSH requests from trusted servers, such as a bastion host or VPN server.
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Provision the server using remote-exec
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "example_provisioner" {
  triggers = {
    public_ip = aws_instance.example_public.public_ip
  }

  connection {
    type  = "ssh"
    host  = aws_instance.example_public.public_ip
    user  = var.ssh_user
    port  = var.ssh_port
    agent = true
  }

  // copy our example script to the server
  provisioner "local-exec" {
    # copy the public-ip file back to CWD, which will be tested
    command = "zip -r files/gojek_ssh_monitoring_client.zip ../src/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y python3 python3-pip unzip",
      "export LC_ALL=en_US.UTF-8",
      "export LC_CTYPE=en_US.UTF-8",
      "pip3 install inotify",
    ]
  }

  provisioner "file" {
    source = "files/gojek_ssh_monitoring_client.zip"
    destination = "/tmp/gojek_ssh_monitoring_client.zip"
  }

  provisioner "file" {
    source = "files/default"
    destination = "/tmp/default"
  }

  provisioner "file" {
    source = "files/gojekmonitoring.service"
    destination = "/tmp/gojekmonitoring.service"
  }

  provisioner "file" {
    source      = "files/get-public-ip.sh"
    destination = "/tmp/get-public-ip.sh"
  }

  // change permissions to executable and pipe its output into a new file
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/get-public-ip.sh",
      "/tmp/get-public-ip.sh > /tmp/public-ip",
      "unzip /tmp/gojek_ssh_monitoring_client.zip -d /tmp/",
      "sudo \\cp /tmp/gojekmonitoring.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",
      "sudo systemctl start gojekmonitoring",
      "sudo systemctl enable gojekmonitoring",
      "sudo systemctl restart nginx",
    ]
  }

  provisioner "local-exec" {
    # copy the public-ip file back to CWD, which will be tested
    command = "scp ${var.ssh_user}@${aws_instance.example_public.public_ip}:/tmp/public-ip public-ip"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# LOOK UP THE LATEST UBUNTU AMI
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20211129"]
  }
}