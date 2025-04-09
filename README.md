# LiteLLM on AWS Fargate with AWS Client VPN

<p align="center">
  <img src="docs/images/litellm-aws-architecture.png" alt="LiteLLM AWS Architecture" width="800"/>
</p>

> **Note:** This repository contains Terraform code to deploy LiteLLM as a containerized application on AWS Fargate in a private subnet, with secure access provided through AWS Client VPN.

## Table of Contents

- [Introduction](#introduction)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Deployment Guide](#deployment-guide)
- [Accessing LiteLLM](#accessing-litellm-via-aws-client-vpn)
- [Using LiteLLM](#using-litellm)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Cost Optimization](#cost-optimization)
- [Contributing](#contributing)
- [License](#license)

## Introduction

[LiteLLM](https://github.com/BerriAI/litellm) is an open-source library that provides a unified interface to various LLM APIs, including OpenAI, Anthropic, AWS Bedrock, and more. This project deploys LiteLLM as a proxy server on AWS Fargate, allowing you to:

- **Centralize LLM API access** for your organization
- **Track usage and costs** across different LLM providers
- **Load balance** between multiple LLM providers
- **Implement rate limiting** and other controls
- **Secure access** to your LLM proxy through AWS Client VPN

This deployment is designed with security in mind, placing the LiteLLM service in a private subnet with no direct internet access, and using AWS Client VPN for secure access.

## Architecture

The architecture consists of the following components:

<p align="center">
  <img src="docs/images/litellm-aws-components.png" alt="LiteLLM AWS Components" width="600"/>
</p>

1. **VPC with Private Subnets**: 
   - LiteLLM runs in a private subnet with no direct internet access
   - NAT Gateway provides outbound internet access for the container

2. **AWS Fargate**: 
   - Hosts the LiteLLM container in Amazon ECS
   - Serverless compute platform (no EC2 instances to manage)
   - Autoscaling based on CPU and memory utilization

3. **Internal Application Load Balancer**: 
   - Routes traffic to the Fargate service
   - Performs health checks on the container
   - Enables horizontal scaling of the service

4. **AWS Client VPN**: 
   - Provides secure VPN access to the internal ALB
   - Uses certificate-based authentication
   - Restricts access to authorized users only

5. **Aurora PostgreSQL**: 
   - Serverless v2 database for LiteLLM
   - Stores API keys, usage data, and configuration
   - Autoscales based on database load

## Prerequisites

Before deploying this solution, ensure you have:

- **AWS Account** with appropriate permissions
- **AWS CLI** installed and configured (version 2.0.0 or later)
- **Terraform** installed (version 1.0.0 or later)
- **OpenVPN-compatible client** for connecting to the VPN (e.g., AWS VPN Client, Tunnelblick, OpenVPN Connect)
- **SSL/TLS certificate** in AWS Certificate Manager (ACM) for the Client VPN endpoint

### Required AWS Permissions

The AWS user or role deploying this solution needs permissions to create and manage:

- VPC and networking resources
- ECS Fargate services and tasks
- Aurora PostgreSQL databases
- Client VPN endpoints
- IAM roles and policies
- CloudWatch logs and metrics

## Deployment Guide

### Step 1: Prepare Your Environment

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/litellm-aws-fargate.git
   cd litellm-aws-fargate
   ```

2. Create an SSL/TLS certificate in AWS Certificate Manager:
   ```bash
   aws acm request-certificate \
     --domain-name your-vpn-certificate.example.com \
     --validation-method DNS
   ```
   
   Follow the validation process in the AWS Console. Once validated, note the certificate ARN.

### Step 2: Configure Deployment Parameters

1. Create a `terraform.tfvars` file based on the example:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit the `terraform.tfvars` file with your specific configuration:
   ```hcl
   aws_region           = "us-east-1"
   project_name         = "litellm"
   environment          = "dev"
   vpn_certificate_arn  = "arn:aws:acm:region:account:certificate/certificate-id"  # Your ACM certificate ARN
   ```

### Step 3: Deploy the Infrastructure

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Preview the changes:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```
   
   Or use the provided deployment script:
   ```bash
   ./deploy.sh
   ```

4. After successful deployment, note the outputs:
   ```bash
   terraform output
   ```
   
   Save these outputs for later use:
   - `client_vpn_endpoint_dns_name`
   - `client_vpn_self_service_portal_url`
   - `litellm_internal_endpoint`
   - `litellm_master_key` (sensitive)

### Step 4: Configure LiteLLM (First-time Setup)

After deployment, you'll need to configure LiteLLM with your API keys and settings:

1. Connect to the VPN (see next section)
2. Access the LiteLLM admin interface at `http://<litellm_internal_endpoint>/admin`
3. Log in with the master key from the Terraform output
4. Configure your LLM providers, API keys, and other settings

## Accessing LiteLLM via AWS Client VPN

### Step 1: Find Your Client VPN Endpoint Information

After deployment, find the Client VPN endpoint information in the Terraform outputs:

```bash
terraform output client_vpn_endpoint_dns_name
terraform output client_vpn_self_service_portal_url
```

### Step 2: Connect to the VPN from Your Computer

#### Option 1: Using the AWS Client VPN Self-Service Portal (Recommended)

1. Navigate to the self-service portal URL from the Terraform output
2. Download the VPN configuration file
3. Import the configuration into your OpenVPN client:
   - **Windows**: AWS VPN Client or OpenVPN Connect
   - **macOS**: Tunnelblick or AWS VPN Client
   - **Linux**: OpenVPN client
4. Connect to the VPN

#### Option 2: Using the AWS CLI

1. Find your Client VPN endpoint ID:
   ```bash
   aws ec2 describe-client-vpn-endpoints --query "ClientVpnEndpoints[?ClientVpnEndpointId].ClientVpnEndpointId" --output text
   ```

2. Download the Client VPN endpoint configuration:
   ```bash
   aws ec2 export-client-vpn-client-configuration \
     --client-vpn-endpoint-id <endpoint-id> \
     --output text > client-config.ovpn
   ```

3. Import the configuration into your OpenVPN client
4. Connect to the VPN

### Step 3: Verify VPN Connection

Once connected to the VPN:

1. Check that you can access internal AWS resources
2. Verify DNS resolution for the internal ALB:
   ```bash
   ping $(terraform output -raw litellm_internal_endpoint)
   ```

## Using LiteLLM

### Accessing the Admin Interface

1. Connect to the VPN
2. Open your browser and navigate to:
   ```
   http://<litellm_internal_endpoint>/admin
   ```
3. Log in with the master key from the Terraform output

### Using the API

You can use the LiteLLM API through the internal ALB:

```bash
# Example: Make a request to LiteLLM
curl -X POST "http://<litellm_internal_endpoint>/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your_litellm_key" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### Creating API Keys

1. Access the admin interface
2. Navigate to the "API Keys" section
3. Create a new key with appropriate permissions and team assignment
4. Use this key in your applications

### Configuring Models

1. Access the admin interface
2. Navigate to the "Model Management" section
3. Add your LLM provider API keys
4. Configure model routing and fallbacks

## Troubleshooting

### Cannot Connect to the VPN

1. **Verify your VPN configuration**:
   - Ensure you're using the correct VPN configuration file
   - Check that your OpenVPN client is properly configured

2. **Check AWS Client VPN logs**:
   - In the AWS Console, navigate to VPC > Client VPN Endpoints > your endpoint > Connections
   - Look for connection errors or authorization issues

3. **Verify security groups**:
   - Ensure the security groups allow traffic from the VPN CIDR range
   - Check that the VPN endpoint security group is properly configured

4. **Certificate issues**:
   - Verify that your ACM certificate is valid and properly associated with the VPN endpoint

### Cannot Access the LiteLLM Service

1. **Verify VPN connection**:
   - Ensure you're connected to the VPN
   - Check your IP address to confirm you're on the VPN network

2. **Check internal ALB DNS resolution**:
   - Try pinging the internal ALB DNS name
   - Use `nslookup` or `dig` to verify DNS resolution

3. **Verify security groups**:
   - Ensure the ALB security group allows traffic from the VPN CIDR range
   - Check that the Fargate task security group allows traffic from the ALB

4. **Check Fargate service health**:
   - In the AWS Console, navigate to ECS > Clusters > your cluster > Services
   - Check that the service is running and tasks are healthy
   - Review the service events for any deployment issues

5. **Check container logs**:
   - In the AWS Console, navigate to CloudWatch > Log Groups
   - Find the log group for your LiteLLM service
   - Review the logs for any application errors

## Security Considerations

This deployment includes several security features:

- **Private Subnet Isolation**: LiteLLM runs in a private subnet with no direct internet access
- **VPN Access**: All access to the service is through an encrypted VPN tunnel
- **Certificate-based Authentication**: Client VPN uses certificates for authentication
- **Encrypted Database**: Aurora PostgreSQL encrypts data at rest
- **IAM Role Separation**: Different IAM roles for different components
- **No Hardcoded Secrets**: Sensitive values are generated or provided at deployment time

### Additional Security Recommendations

1. **Enable AWS WAF** for the internal ALB to protect against common web exploits
2. **Implement AWS CloudTrail** to monitor API calls and detect suspicious activity
3. **Use AWS Config** to monitor and enforce security policies
4. **Regularly rotate** API keys and credentials
5. **Enable database encryption in transit** for Aurora PostgreSQL

## Cost Optimization

This deployment is designed to be cost-effective while maintaining performance and security:

- **Fargate Spot** can be enabled for non-production workloads to reduce costs
- **Aurora Serverless v2** scales based on actual database usage
- **Autoscaling** adjusts capacity based on demand
- **Client VPN endpoints** incur charges per hour of operation and per client connection

### Cost Reduction Strategies

1. **Schedule scaling** to reduce capacity during off-hours:
   ```hcl
   # Add to main.tf
   resource "aws_appautoscaling_scheduled_action" "scale_down" {
     name               = "${var.project_name}-scale-down"
     service_namespace  = "ecs"
     resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
     scalable_dimension = "ecs:service:DesiredCount"
     schedule           = "cron(0 20 * * ? *)"  # 8 PM UTC
     
     scalable_target_action {
       min_capacity = 0
       max_capacity = 0
     }
   }
   ```

2. **Disable Client VPN** when not in use:
   ```bash
   aws ec2 modify-client-vpn-endpoint \
     --client-vpn-endpoint-id <endpoint-id> \
     --vpc-id <vpc-id> \
     --server-certificate-arn <certificate-arn> \
     --connection-log-options Enabled=false
   ```

3. **Use smaller Fargate task sizes** for development environments

## Contributing

Contributions to this project are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
