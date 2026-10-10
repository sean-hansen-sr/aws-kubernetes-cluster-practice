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

# IAM Role for SSM
resource "aws_iam_role" "ssm_role" {
  name = "ubuntu-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "://amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AmazonSSMManagedInstanceCore policy
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create Instance Profile
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ubuntu-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

# Deploy 3 Ubuntu VMs with No External IP
resource "aws_instance" "ubuntu_vm" {
  count                  = 3
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

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
