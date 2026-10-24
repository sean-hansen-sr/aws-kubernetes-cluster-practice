# Get Latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Deploy 3 Ubuntu VMs with No External IP
resource "aws_instance" "ubuntu_vm" {
  count                  = 3
  # Sets Latest Ubuntu 22.04 AMI
  # ami                    = data.aws_ami.ubuntu.id
  # Statically set AMI 
  ami                    = var.ami_id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # Assign Private IP Address
  private_ip = var.kubernetes_private_ips[count.index]

  # Configure the root storage drive to 60 GB
  root_block_device {
    volume_size           = 60
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # This explicitly prevents assigning a public/external IP address
  associate_public_ip_address = false

  tags = {
    Name = count.index == 0 ? "ubuntu-control-plane-${count.index + 1}" : "ubuntu-worker-node-${count.index}"
    Role = count.index == 0 ? "Control_Plane_${count.index + 1}" : "Worker_Node_${count.index}"
  }
}
