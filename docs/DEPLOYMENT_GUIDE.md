# AWS VM Deployment Guide

This guide covers deploying the AWS VM with Open Web UI using both Bricks CLI (recommended) and direct Terraform.

## Method 1: Deploy with Bricks CLI (Recommended)

### Prerequisites
1. **Bricks CLI** installed and configured
2. **AWS Account** with programmatic access
3. **AWS Credentials** configured as environment variables
4. **SSH Key** generated for VM access

### Quick Deployment

1. **Configure AWS Credentials**
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_REGION="eu-central-1"
   ```

2. **Deploy with Bricks**
   ```bash
   # Basic CPU deployment
   bricks run . --var ssh_pub_key="~/.ssh/terraform-aws.pub"

   # GPU deployment for local LLMs
   bricks run . --var gpu_enabled=true --var ssh_pub_key="~/.ssh/terraform-aws.pub"

   # With OpenAI integration
   bricks run . \
     --var ssh_pub_key="~/.ssh/terraform-aws.pub" \
     --var openai_key="your-openai-api-key"
   ```

3. **Using Variables File**
   Create `variables.yaml`:
   ```yaml
   region: "eu-central-1"
   gpu_enabled: false
   ssh_pub_key: "~/.ssh/terraform-aws.pub"
   open_webui_user: "admin@yourcompany.com"
   openai_key: "your-openai-api-key"
   ```

   Deploy:
   ```bash
   bricks run . --var-file variables.yaml
   ```

## Method 2: Direct Terraform Deployment

### Prerequisites
1. **AWS Account** with programmatic access
2. **AWS Credentials** configured (see setup-credentials.sh)
3. **Terraform** installed (v1.12+ recommended)
4. **SSH Key** generated for VM access

### Deployment Steps

1. **Configure AWS Credentials**
   ```bash
   # Set environment variables
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_REGION="eu-central-1"

   # Or run the setup script
   ./setup-credentials.sh
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review Configuration**
   ```bash
   # Edit terraform.tfvars if needed
   nano terraform.tfvars

   # Plan deployment
   terraform plan
   ```

4. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

5. **Access Your VM**
   ```bash
   # Get public IP
   terraform output public_ip
   
   # SSH to VM
   ssh admin@$(terraform output -raw public_ip) -i ~/.ssh/terraform-aws
   
   # Get web UI password
   terraform output password
   ```

## What Gets Deployed

### AWS Resources
- **VPC** (10.1.0.0/16) with internet gateway
- **Subnet** (10.1.16.0/20) in availability zone A
- **Security Groups** for SSH (22) and HTTP (80) access
- **EC2 Spot Instance** (t3.micro for CPU, g4dn.xlarge for GPU)
- **Key Pair** for SSH access

### Software Stack
- **Debian 11** base operating system
- **Docker** container runtime
- **Open Web UI** - LLM interface accessible via web browser
- **Optional**: NVIDIA drivers and container toolkit (GPU instances)

### Instance Types
- **CPU Instance (t3.micro)**: Free tier eligible, requires OpenAI API for LLM functionality
- **GPU Instance (g4dn.xlarge)**: Can run local LLMs, ~$0.50/hour

## Configuration Options

### terraform.tfvars Variables
```hcl
region = "eu-central-1"           # AWS region
gpu_enabled = false               # true for GPU instance
ssh_pub_key = "~/.ssh/terraform-aws.pub"  # SSH public key path
open_webui_user = "admin@demo.gs" # Web UI username
openai_key = ""                   # OpenAI API key (optional)
```

### Security Considerations
- SSH access from anywhere (0.0.0.0/0) - restrict for production
- HTTP access from anywhere (0.0.0.0/0) - restrict for production
- Uses SSH key authentication (no password access)
- Random password generated for web UI

## Accessing Open Web UI

1. **Get Connection Details**
   ```bash
   echo "Public IP: $(terraform output -raw public_ip)"
   echo "Password: $(terraform output -raw password)"
   ```

2. **Open Web Browser**
   - Navigate to: `http://[PUBLIC_IP]`
   - Username: `admin@demo.gs` (or your configured value)
   - Password: Use the generated password from terraform output

3. **Configure LLM Backend**
   - **CPU Instance**: Configure OpenAI API in settings
   - **GPU Instance**: Install local models (Ollama, etc.)

## Troubleshooting

### Common Issues
1. **AWS Credentials**: Ensure proper IAM permissions
2. **SSH Key**: Verify public key path in terraform.tfvars
3. **Region**: Some regions may not have g4dn instances
4. **Spot Instance**: May take time to fulfill or fail if capacity unavailable

### Useful Commands
```bash
# Check deployment status
terraform show

# View logs
ssh admin@$(terraform output -raw public_ip) -i ~/.ssh/terraform-aws
sudo journalctl -u openwebui.service -f

# Check container status
sudo docker ps
sudo docker logs openwebui.service
```

## Cleanup

**Important**: Always clean up resources to avoid charges
```bash
terraform destroy
```

## Cost Estimation
- **t3.micro**: Free tier eligible (750 hours/month)
- **g4dn.xlarge**: ~$0.526/hour on-demand, less for spot instances
- **Storage**: ~$6/month for 60GB EBS volume
- **Data Transfer**: Minimal for testing

## Next Steps
1. Configure OpenAI API (CPU instances)
2. Install local LLMs (GPU instances)
3. Explore Open Web UI features
4. Set up custom models and workflows
