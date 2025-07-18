output "public_ip" {
  description = "Public IP address of the OpenWebUI instance"
  value       = aws_spot_instance_request.openwebui.public_ip
}

output "elastic_ip" {
  description = "Elastic IP address assigned to the instance"
  value       = aws_eip.openwebui.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = data.aws_instance.openwebui.id
}

output "instance_type" {
  description = "EC2 instance type"
  value       = data.aws_instance.openwebui.instance_type
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = data.aws_instance.openwebui.availability_zone
}

output "password" {
  description = "Generated password for OpenWebUI access"
  sensitive   = true
  value       = random_password.password.result
}

output "username" {
  description = "Username for OpenWebUI access"
  value       = var.open_webui_user
}

output "web_url" {
  description = "URL to access OpenWebUI"
  value       = "http://${aws_eip.openwebui.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh admin@${aws_eip.openwebui.public_ip} -i ~/.ssh/terraform-aws"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.openwebui.id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value = {
    public  = aws_subnet.public.id
    private = aws_subnet.private.id
  }
}

output "security_group_ids" {
  description = "Security group IDs"
  value = {
    ssh = aws_security_group.ssh.id
    web = aws_security_group.web.id
  }
}

output "key_pair_name" {
  description = "AWS key pair name"
  value       = aws_key_pair.openwebui.key_name
}

output "deployment_info" {
  description = "Deployment information summary"
  value = {
    region            = var.region
    instance_type     = var.gpu_enabled ? var.machine.gpu.type : var.machine.cpu.type
    gpu_enabled       = var.gpu_enabled
    ami_id           = data.aws_ami.debian.id
    deployment_id    = random_id.suffix.hex
  }
}