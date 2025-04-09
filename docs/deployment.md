# LiteLLM AWS Fargate Deployment Guide

This guide provides detailed instructions for deploying the LiteLLM proxy service on AWS Fargate with Client VPN access.

## Prerequisites

Before you begin, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured (version 2.0.0 or later)
   ```bash
   aws --version
   ```
3. **Terraform** installed (version 1.0.0 or later)
   ```bash
   terraform --version
   ```
4. **OpenVPN-compatible client** installed on your computer
5. **SSL/TLS certificate** in AWS Certificate Manager (ACM)

## Step 1: Create an SSL/TLS Certificate

The Client VPN endpoint requires a server certificate in AWS Certificate Manager (ACM).

### Option 1: Request a Certificate from ACM (Recommended)

1. Open the AWS Management Console and navigate to ACM
2. Click "Request a certificate"
3. Select "Request a public certificate"
4. Enter a domain name (e.g., `vpn.example.com`)
5. Select "DNS validation" or "Email validation"
6. Click "Request"
7. Complete the validation process
8. Note the certificate ARN for use in Terraform

### Option 2: Import an Existing Certificate

1. Generate a self-signed certificate using OpenSSL:
   ```bash
   # Generate a private key
   openssl genrsa -out private-key.pem 2048
   
   # Generate a certificate signing request
   openssl req -new -key private-key.pem -out csr.pem
   
   # Generate a self-signed certificate
   openssl x509 -req -in csr.pem -key private-key.pem -out certificate.pem -days 365
   ```

2. Import the certificate into ACM:
   ```bash
   aws acm import-certificate \
     --certificate fileb://certificate.pem \
     --private-key fileb://private-key.pem
   ```

3. Note the certificate ARN from the output

## Step 2: Clone the Repository

```bash
git clone https://github.com/yourusername/litellm-aws-fargate.git
cd litellm-aws-fargate
```

## Step 3: Configure Deployment Parameters

1. Create a `terraform.tfvars` file based on the example:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit the `terraform.tfvars` file with your specific configuration:
   ```hcl
   # Required parameters
   aws_region           = "us-east-1"
   project_name         = "litellm"
   environment          = "dev"
   vpn_certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
   
   # Optional parameters - adjust as needed
   vpc_cidr             = "10.0.0.0/16"
   availability_zones   = ["us-east-1a", "us-east-1b"]
   client_vpn_cidr      = "172.16.0.0/22"
   ```

## Step 4: Initialize Terraform

```bash
terraform init
```

This command initializes the Terraform working directory, downloads the required providers, and sets up the backend.

## Step 5: Preview the Changes

```bash
terraform plan
```

Review the plan to ensure it will create the expected resources. The plan should show:

- VPC and networking resources
- Aurora PostgreSQL database
- ECR repository and container image
- ECS Fargate service and task definition
- Client VPN endpoint
- IAM roles and policies
- CloudWatch logs and S3 bucket for logging

## Step 6: Deploy the Infrastructure

```bash
terraform apply
```

When prompted, type `yes` to confirm the deployment. Alternatively, use the provided deployment script:

```bash
./deploy.sh
```

The deployment will take approximately 15-20 minutes to complete.

## Step 7: Save the Outputs

After successful deployment, save the Terraform outputs:

```bash
terraform output
```

Important outputs to note:
- `client_vpn_endpoint_dns_name`: DNS name of the Client VPN endpoint
- `client_vpn_self_service_portal_url`: URL of the self-service portal
- `litellm_internal_endpoint`: Internal ALB DNS name for accessing LiteLLM
- `litellm_master_key`: Master key for LiteLLM admin access (sensitive)

## Step 8: Connect to the VPN

### Using the AWS Client VPN Self-Service Portal

1. Navigate to the self-service portal URL from the Terraform output
2. Download the VPN configuration file
3. Import the configuration into your OpenVPN client:
   - **Windows**: AWS VPN Client or OpenVPN Connect
   - **macOS**: Tunnelblick or AWS VPN Client
   - **Linux**: OpenVPN client
4. Connect to the VPN

### Using the AWS CLI

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

## Step 9: Configure LiteLLM

After connecting to the VPN, you can access the LiteLLM admin interface:

1. Open your browser and navigate to:
   ```
   http://<litellm_internal_endpoint>/admin
   ```

2. Log in with the master key from the Terraform output

3. Configure your LLM providers:
   - Add API keys for OpenAI, Anthropic, etc.
   - Configure model routing and fallbacks
   - Set up teams and users
   - Create API keys for your applications

## Step 10: Test the Deployment

Test the LiteLLM API with a simple request:

```bash
curl -X POST "http://<litellm_internal_endpoint>/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your_litellm_key>" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Updating the Deployment

To update the deployment after making changes to the Terraform configuration:

```bash
terraform plan  # Preview changes
terraform apply # Apply changes
```

## Destroying the Infrastructure

To destroy all resources created by Terraform:

```bash
terraform destroy
```

When prompted, type `yes` to confirm. This will delete all resources, including the database, so ensure you have backups if needed.

## Troubleshooting

### VPN Connection Issues

1. **Certificate problems**:
   - Ensure the certificate is valid and properly associated with the VPN endpoint
   - Check that the certificate is in the same region as the VPN endpoint

2. **Connection timeouts**:
   - Verify that the security groups allow traffic from the VPN CIDR range
   - Check that the VPN endpoint is associated with the correct subnets

3. **Authentication failures**:
   - Ensure you're using the correct VPN configuration file
   - Check the Client VPN endpoint logs in CloudWatch

### LiteLLM Access Issues

1. **Cannot reach the LiteLLM service**:
   - Verify you're connected to the VPN
   - Check that the Fargate service is running
   - Ensure the ALB security group allows traffic from the VPN CIDR range

2. **Database connection errors**:
   - Check the Fargate service logs in CloudWatch
   - Verify the database is running and accessible
   - Ensure the database security group allows traffic from the Fargate tasks

3. **Container health check failures**:
   - Check the container logs in CloudWatch
   - Verify the health check path is correct
   - Ensure the container is properly configured with environment variables
