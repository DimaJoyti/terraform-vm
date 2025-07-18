# Get availability zones for the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get the latest AMI
data "aws_ami" "debian" {
  most_recent = true
  filter {
    name   = "name"
    values = [var.ami_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  owners = var.ami_owners
}

# Create a random password for the web UI
resource "random_password" "password" {
  length  = 20
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Create a random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_vpc" "openwebui" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "openwebui-vpc-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
  }
}

# Create public subnet
resource "aws_subnet" "public" {
  cidr_block              = cidrsubnet(aws_vpc.openwebui.cidr_block, 8, 1)
  vpc_id                  = aws_vpc.openwebui.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "openwebui-public-subnet-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
    Type        = "public"
  }
}

# Create private subnet for future use
resource "aws_subnet" "private" {
  cidr_block        = cidrsubnet(aws_vpc.openwebui.cidr_block, 8, 2)
  vpc_id            = aws_vpc.openwebui.id
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "openwebui-private-subnet-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
    Type        = "private"
  }
}

resource "aws_internet_gateway" "openwebui" {
  vpc_id = aws_vpc.openwebui.id

  tags = {
    Name        = "openwebui-igw-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
  }
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.openwebui.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.openwebui.id
  }

  tags = {
    Name        = "openwebui-public-rt-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
    Type        = "public"
  }
}

# Associate public subnet with public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway for private subnet (optional, for future use)
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "openwebui-nat-eip-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
  }

  depends_on = [aws_internet_gateway.openwebui]
}

resource "aws_nat_gateway" "openwebui" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "openwebui-nat-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
  }

  depends_on = [aws_internet_gateway.openwebui]
}

# Private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.openwebui.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.openwebui.id
  }

  tags = {
    Name        = "openwebui-private-rt-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
    Type        = "private"
  }
}

# Associate private subnet with private route table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security group for SSH access
resource "aws_security_group" "ssh" {
  name_prefix = "openwebui-ssh-${random_id.suffix.hex}-"
  description = "Security group for SSH access to OpenWebUI instance"
  vpc_id      = aws_vpc.openwebui.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Restrict to your IP for production
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "openwebui-ssh-sg-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
    Purpose     = "ssh-access"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security group for HTTP/HTTPS access
resource "aws_security_group" "web" {
  name_prefix = "openwebui-web-${random_id.suffix.hex}-"
  description = "Security group for web access to OpenWebUI"
  vpc_id      = aws_vpc.openwebui.id

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "OpenWebUI direct access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "openwebui-web-sg-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
    Purpose     = "web-access"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# SSH Key Pair
resource "aws_key_pair" "openwebui" {
  key_name   = "openwebui-${random_id.suffix.hex}"
  public_key = file(var.ssh_pub_key)

  tags = {
    Name        = "openwebui-keypair-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
  }
}

# IAM role for EC2 instance
resource "aws_iam_role" "openwebui_instance_role" {
  name_prefix = "openwebui-instance-role-${random_id.suffix.hex}-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "openwebui-instance-role-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
  }
}

# IAM instance profile
resource "aws_iam_instance_profile" "openwebui_profile" {
  name_prefix = "openwebui-profile-${random_id.suffix.hex}-"
  role        = aws_iam_role.openwebui_instance_role.name

  tags = {
    Name        = "openwebui-profile-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
  }
}

# Launch template for better instance management
resource "aws_launch_template" "openwebui" {
  name_prefix   = "openwebui-lt-${random_id.suffix.hex}-"
  description   = "Launch template for OpenWebUI instances"
  image_id      = var.custom_ami != "" ? var.custom_ami : data.aws_ami.debian.id
  instance_type = var.gpu_enabled ? var.machine.gpu.type : var.machine.cpu.type
  key_name      = aws_key_pair.openwebui.key_name

  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.web.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.openwebui_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 60
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/${var.provision_script}", {
    gpu_enabled         = var.gpu_enabled
    open_webui_user     = var.open_webui_user
    open_webui_password = random_password.password.result
    openai_base         = var.openai_base
    openai_key          = var.openai_key
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "openwebui-instance-${random_id.suffix.hex}"
      Environment = "demo"
      Project     = "terraform-vm"
      Type        = var.gpu_enabled ? "gpu" : "cpu"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "openwebui-volume-${random_id.suffix.hex}"
      Environment = "demo"
      Project     = "terraform-vm"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Spot instance request using launch template
resource "aws_spot_instance_request" "openwebui" {
  launch_template {
    id      = aws_launch_template.openwebui.id
    version = "$Latest"
  }

  spot_price                      = var.gpu_enabled ? "0.50" : "0.01"
  wait_for_fulfillment           = true
  spot_type                      = "one-time"
  instance_interruption_behavior = "terminate"

  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name        = "openwebui-spot-request-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
  }
}

# Get the actual instance from the spot request
data "aws_instance" "openwebui" {
  filter {
    name   = "spot-instance-request-id"
    values = [aws_spot_instance_request.openwebui.id]
  }

  depends_on = [aws_spot_instance_request.openwebui]
}

# Create a terracurl request to check if the web server is up and running
# Wait a max of 20 minutes with a 10 second interval
resource "terracurl_request" "openwebui_health_check" {
  name   = "openwebui-health-check"
  url    = "http://${aws_spot_instance_request.openwebui.public_ip}"
  method = "GET"

  response_codes = [200, 302]
  max_retry      = 120
  retry_interval = 10

  depends_on = [aws_spot_instance_request.openwebui]
}

# CloudWatch Log Group for instance logs (optional)
resource "aws_cloudwatch_log_group" "openwebui" {
  name              = "/aws/ec2/openwebui-${random_id.suffix.hex}"
  retention_in_days = 7

  tags = {
    Name        = "openwebui-logs-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
  }
}

# Elastic IP for consistent access (optional)
resource "aws_eip" "openwebui" {
  instance = data.aws_instance.openwebui.id
  domain   = "vpc"

  tags = {
    Name        = "openwebui-eip-${random_id.suffix.hex}"
    Environment = "demo"
    Project     = "terraform-vm"
  }

  depends_on = [aws_internet_gateway.openwebui, data.aws_instance.openwebui]
}
