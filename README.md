# Terraform VM

Multi-cloud Terraform configurations for deploying virtual machines with Open Web UI across AWS, Azure, and Google Cloud Platform.

## Overview

This repository contains complete Terraform examples that demonstrate deploying virtual machines with Open Web UI - a web interface for running Large Language Models (LLMs) locally or integrating with OpenAI-compatible APIs.

## Cloud Providers

Each cloud provider has its own directory with complete infrastructure configurations:

- **[AWS](aws/)** - Deploy on Amazon Web Services with EC2 instances
- **[Azure](azure/)** - Deploy on Microsoft Azure with ARM resources  
- **[GCP](gcp/)** - Deploy on Google Cloud Platform with Compute Engine
- **[Basics](basics/)** - Learn Terraform fundamentals with local Docker containers

## Features

- **Multi-cloud support** - Choose your preferred cloud provider
- **GPU and CPU options** - Deploy either GPU-enabled instances for local LLMs or CPU instances with OpenAI integration
- **Complete infrastructure** - Includes networking, security groups, and compute resources
- **Automated provisioning** - Cloud-init scripts handle application setup
- **Secure deployment** - Uses environment variables for credentials and generates secure passwords

## Quick Start

1. **Choose your cloud provider** and navigate to the appropriate directory
2. **Set up authentication** - Configure cloud provider credentials as environment variables
3. **Deploy infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
4. **Access your deployment** - Use the output IP address and generated password

## Requirements

- Terraform installed on your machine
- Cloud provider account with appropriate permissions
- Optional: OpenAI API key for LLM integration
- Optional: SSH public key for VM access

## Documentation

- Each provider directory contains detailed setup instructions
- See [CLAUDE.md](CLAUDE.md) for development guidance
- Check individual README files for provider-specific requirements

## Security

- Never commit API keys or credentials to the repository
- Use environment variables for sensitive configuration
- All instances are configured with appropriate security controls