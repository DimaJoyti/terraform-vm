#!/bin/bash

# Terraform Configuration Validation Script
# This script validates the updated Terraform configuration

set -e

echo "🔍 Terraform Configuration Validation"
echo "======================================"

# Check if we're in the right directory
if [[ ! -f "main.tf" || ! -f "vm.tf" ]]; then
    echo "❌ Error: Please run this script from the aws/ directory"
    exit 1
fi

echo ""
echo "1. Checking Terraform installation..."
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    echo "✅ Terraform installed: v$TERRAFORM_VERSION"
else
    echo "❌ Terraform not found. Please install Terraform first."
    exit 1
fi

echo ""
echo "2. Validating Terraform configuration..."
if terraform validate; then
    echo "✅ Terraform configuration is valid"
else
    echo "❌ Terraform configuration validation failed"
    exit 1
fi

echo ""
echo "3. Checking required files..."
REQUIRED_FILES=("main.tf" "vm.tf" "output.tf" "terraform.tfvars")
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ Found: $file"
    else
        echo "❌ Missing: $file"
        exit 1
    fi
done

echo ""
echo "4. Checking SSH key configuration..."
SSH_KEY_PATH=$(grep -o '~/.ssh/terraform-aws.pub' terraform.tfvars || echo "")
if [[ -n "$SSH_KEY_PATH" ]]; then
    EXPANDED_PATH="${SSH_KEY_PATH/#\~/$HOME}"
    if [[ -f "$EXPANDED_PATH" ]]; then
        echo "✅ SSH public key found: $EXPANDED_PATH"
    else
        echo "⚠️  SSH public key not found: $EXPANDED_PATH"
        echo "   Run: ssh-keygen -t rsa -b 4096 -f ~/.ssh/terraform-aws -N ''"
    fi
else
    echo "⚠️  SSH key path not configured in terraform.tfvars"
fi

echo ""
echo "5. Checking AWS credentials..."
if [[ -n "$AWS_ACCESS_KEY_ID" && -n "$AWS_SECRET_ACCESS_KEY" ]]; then
    echo "✅ AWS credentials found in environment variables"
    echo "   Region: ${AWS_REGION:-not set}"
elif command -v aws &> /dev/null && aws sts get-caller-identity &> /dev/null; then
    echo "✅ AWS credentials configured via AWS CLI"
    CURRENT_REGION=$(aws configure get region 2>/dev/null || echo "not set")
    echo "   Region: $CURRENT_REGION"
else
    echo "⚠️  AWS credentials not configured"
    echo "   Set environment variables or run: aws configure"
fi

echo ""
echo "6. Checking Terraform initialization..."
if [[ -d ".terraform" ]]; then
    echo "✅ Terraform initialized"
else
    echo "⚠️  Terraform not initialized"
    echo "   Run: terraform init"
fi

echo ""
echo "7. Configuration summary..."
echo "   Region: $(grep 'region =' terraform.tfvars | cut -d'"' -f2)"
echo "   GPU Enabled: $(grep 'gpu_enabled =' terraform.tfvars | awk '{print $3}')"
echo "   Environment: $(grep 'environment =' terraform.tfvars | cut -d'"' -f2)"
echo "   Project: $(grep 'project_name =' terraform.tfvars | cut -d'"' -f2)"

echo ""
echo "8. Security recommendations..."
SSH_CIDRS=$(grep -o 'allowed_ssh_cidrs.*' terraform.tfvars | grep -v '#' || echo "")
WEB_CIDRS=$(grep -o 'allowed_web_cidrs.*' terraform.tfvars | grep -v '#' || echo "")

if [[ -z "$SSH_CIDRS" ]]; then
    echo "⚠️  SSH access allows all IPs (0.0.0.0/0)"
    echo "   Consider restricting: allowed_ssh_cidrs = [\"YOUR_IP/32\"]"
else
    echo "✅ SSH access restricted"
fi

if [[ -z "$WEB_CIDRS" ]]; then
    echo "⚠️  Web access allows all IPs (0.0.0.0/0)"
    echo "   Consider restricting: allowed_web_cidrs = [\"YOUR_IP/32\"]"
else
    echo "✅ Web access restricted"
fi

echo ""
echo "🎯 Validation Complete!"
echo ""
echo "Next steps:"
echo "1. Configure AWS credentials if not done"
echo "2. Generate SSH keys if not done"
echo "3. Run: terraform init (if not initialized)"
echo "4. Run: terraform plan"
echo "5. Run: terraform apply"
echo ""
echo "For deployment help, see: DEPLOYMENT_GUIDE.md"
echo "For update details, see: UPDATE_SUMMARY.md"
