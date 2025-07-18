#!/bin/bash

# Setup script for AWS VM deployment with Bricks CLI
# This script helps prepare your environment for deployment

set -e

echo "🧱 Bricks CLI - AWS VM Setup"
echo "=============================="

# Check if Bricks CLI is installed
if ! command -v bricks &> /dev/null; then
    echo "❌ Bricks CLI not found. Please install it first."
    echo "   Visit: https://docs.bluebricks.co for installation instructions"
    exit 1
fi

echo "✅ Bricks CLI found: $(bricks --version)"

# Check AWS credentials
echo ""
echo "🔐 Checking AWS credentials..."

if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    echo "❌ AWS credentials not found in environment variables."
    echo ""
    echo "Please set the following environment variables:"
    echo "  export AWS_ACCESS_KEY_ID=\"your-access-key\""
    echo "  export AWS_SECRET_ACCESS_KEY=\"your-secret-key\""
    echo "  export AWS_REGION=\"eu-central-1\"  # or your preferred region"
    echo ""
    echo "Or run: source ./setup-credentials.sh"
    exit 1
fi

echo "✅ AWS credentials configured"
echo "   Region: ${AWS_REGION:-not set}"

# Check/generate SSH key
echo ""
echo "🔑 Checking SSH key..."

SSH_KEY_PATH="$HOME/.ssh/terraform-aws"
SSH_PUB_KEY_PATH="$HOME/.ssh/terraform-aws.pub"

if [[ ! -f "$SSH_PUB_KEY_PATH" ]]; then
    echo "❓ SSH key not found at $SSH_PUB_KEY_PATH"
    read -p "Generate new SSH key? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔧 Generating SSH key..."
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "terraform-aws-vm"
        echo "✅ SSH key generated at $SSH_KEY_PATH"
    else
        echo "❌ SSH key required for deployment. Please generate one manually:"
        echo "   ssh-keygen -t rsa -b 4096 -f ~/.ssh/terraform-aws"
        exit 1
    fi
else
    echo "✅ SSH key found at $SSH_PUB_KEY_PATH"
fi

# Create variables file if it doesn't exist
echo ""
echo "📝 Setting up variables file..."

if [[ ! -f "variables.yaml" ]]; then
    echo "🔧 Creating variables.yaml from template..."
    cp variables.example.yaml variables.yaml
    
    # Update the SSH key path in the variables file
    if command -v sed &> /dev/null; then
        sed -i "s|ssh_pub_key: \"~/.ssh/terraform-aws.pub\"|ssh_pub_key: \"$SSH_PUB_KEY_PATH\"|" variables.yaml
    fi
    
    echo "✅ Created variables.yaml"
    echo "   Please review and customize the variables in variables.yaml"
else
    echo "✅ variables.yaml already exists"
fi

# Final instructions
echo ""
echo "🚀 Setup complete! Next steps:"
echo ""
echo "1. Review and customize variables.yaml:"
echo "   nano variables.yaml"
echo ""
echo "2. Deploy your VM:"
echo "   bricks run . --var-file variables.yaml"
echo ""
echo "   Or with inline variables:"
echo "   bricks run . --var ssh_pub_key=\"$SSH_PUB_KEY_PATH\""
echo ""
echo "3. For GPU deployment:"
echo "   bricks run . --var-file variables.yaml --var gpu_enabled=true"
echo ""
echo "📚 For more options, see DEPLOYMENT_GUIDE.md"
echo ""
echo "⚠️  Security reminder: Update allowed_ssh_cidrs and allowed_web_cidrs"
echo "   in variables.yaml to restrict access to your IP address only!"
