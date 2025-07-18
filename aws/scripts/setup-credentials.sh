#!/bin/bash

# AWS Credentials Setup Script for Terraform VM Deployment
# This script helps you configure AWS credentials for Terraform

echo "=== AWS Credentials Setup for Terraform VM Deployment ==="
echo ""

# Check if AWS credentials are already set
if [[ -n "$AWS_ACCESS_KEY_ID" && -n "$AWS_SECRET_ACCESS_KEY" ]]; then
    echo "✅ AWS credentials are already set in environment variables"
    echo "   AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:0:8}..."
    echo "   AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY:0:8}..."
    echo "   AWS_REGION: ${AWS_REGION:-not set}"
else
    echo "❌ AWS credentials not found in environment variables"
    echo ""
    echo "Please set your AWS credentials using one of these methods:"
    echo ""
    echo "Method 1: Environment Variables (Recommended for this demo)"
    echo "export AWS_ACCESS_KEY_ID=\"your-access-key-id\""
    echo "export AWS_SECRET_ACCESS_KEY=\"your-secret-access-key\""
    echo "export AWS_REGION=\"eu-central-1\"  # or your preferred region"
    echo ""
    echo "Method 2: AWS CLI Configuration"
    echo "aws configure"
    echo ""
    echo "Method 3: Create a .env file (for this project only)"
    echo "Create a file called '.env' in the aws/ directory with:"
    echo "AWS_ACCESS_KEY_ID=your-access-key-id"
    echo "AWS_SECRET_ACCESS_KEY=your-secret-access-key"
    echo "AWS_REGION=eu-central-1"
    echo ""
    echo "Then run: source .env"
    echo ""
    echo "⚠️  IMPORTANT SECURITY NOTES:"
    echo "   - Never commit credentials to version control"
    echo "   - Use IAM users with minimal required permissions"
    echo "   - Consider using AWS IAM roles for production"
    echo ""
    exit 1
fi

echo ""
echo "=== Required AWS Permissions ==="
echo "Your AWS user/role needs these permissions:"
echo "- EC2: CreateInstance, DescribeInstances, TerminateInstances"
echo "- VPC: CreateVpc, CreateSubnet, CreateInternetGateway, etc."
echo "- IAM: CreateKeyPair, DescribeKeyPairs"
echo "- Spot Instances: RequestSpotInstances, DescribeSpotInstanceRequests"
echo ""

# Test AWS credentials
echo "=== Testing AWS Credentials ==="
if command -v aws &> /dev/null; then
    echo "Testing AWS CLI access..."
    aws sts get-caller-identity 2>/dev/null && echo "✅ AWS credentials are valid" || echo "❌ AWS credentials test failed"
else
    echo "AWS CLI not installed - credentials will be tested during Terraform execution"
fi

echo ""
echo "=== Next Steps ==="
echo "1. Ensure AWS credentials are properly configured"
echo "2. Run: cd aws && terraform init"
echo "3. Configure variables in terraform.tfvars"
echo "4. Run: terraform plan"
echo "5. Run: terraform apply"
