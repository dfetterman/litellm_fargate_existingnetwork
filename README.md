# LiteLLM on AWS Fargate with Terraform (Modular)

This project deploys LiteLLM on AWS Fargate using Terraform with a modular structure and standard AWS modules. It provides a scalable, serverless infrastructure for running the LiteLLM proxy server.

## Architecture

The architecture consists of:

- VPC with public, private, and database subnets (using terraform-aws-modules/vpc/aws)
- Aurora PostgreSQL Serverless v2 database for storing configuration and usage data
- ECS Fargate service running the LiteLLM container (using terraform-aws-modules/ecs/aws)
- Internal Application Load Balancer with security group access control
- Auto-scaling based on CPU and memory utilization
- CloudWatch for logs and monitoring with extended retention (90 days)
- AWS Secrets Manager for secure credential management
- S3 bucket for ALB access logs with proper encryption and access policies
- AWS WAF for rate limiting and protection against common web exploits
- Dedicated health check endpoints for container monitoring

## Project Structure

The project is organized into modules:

```
litellm-aws-fargate/
├── main.tf                # Main configuration file
├── variables.tf           # Input variables
├── outputs.tf             # Output values
├── deploy.sh              # Deployment script
├── modules/
│   ├── networking/        # VPC and security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/          # Aurora PostgreSQL database
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── fargate/           # ECS Fargate service
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │   ├── ecr/           # ECR container repository
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── iam/           # IAM roles and policies
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── secrets/       # AWS Secrets Manager
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── templates/
│   │   │       └── litellm_config.yaml.tpl
│   │   └── container/     # Container configuration
│   │       ├── Dockerfile
│   │       ├── startup.sh
│   │       ├── health_check.py
│   │       ├── build_and_push.sh
│   │       └── config/
│   │           └── litellm_config.yaml
│   ├── logging/           # S3 bucket for ALB access logs
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── security/          # WAF and security configurations
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [Docker](https://www.docker.com/get-started) (if you want to build a custom container image)

## Getting Started

1. Clone this repository:

```bash
git clone <repository-url>
cd litellm-aws-fargate
```

2. Create a `terraform.tfvars` file with your configuration:

```hcl
aws_region     = "us-east-1"
project_name   = "litellm"
# Leave db_password empty to auto-generate a secure password
db_password    = ""
# Define on-premises CIDR blocks that can access the internal ALB
on_premises_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]
```

3. Run the deployment script:

```bash
./deploy.sh
```

4. After the deployment is complete, you can access the LiteLLM proxy server from within your VPC or on-premises network at the URL provided in the outputs.

## Configuration

### Variables

| Name | Description | Default |
|------|-------------|---------|
| aws_region | AWS region to deploy resources | us-east-1 |
| project_name | Name of the project | litellm |
| vpc_cidr | CIDR block for the VPC | 10.0.0.0/16 |
| availability_zones | List of availability zones to use | ["us-east-1a", "us-east-1b"] |
| db_name | Name of the database | litellm |
| db_username | Username for the database | litellm |
| db_password | Password for the database (leave empty to auto-generate) | "" |
| min_capacity | Minimum capacity for Aurora Serverless v2 in ACUs | 0.5 |
| db_max_capacity | Maximum capacity for Aurora Serverless v2 in ACUs | 4.0 |
| container_port | Port the container listens on | 4000 |
| cpu | CPU units for the Fargate task | 1024 (1 vCPU) |
| memory | Memory for the Fargate task in MiB | 2048 (2 GB) |
| desired_count | Desired number of tasks | 1 |
| max_capacity | Maximum number of tasks for autoscaling | 2 |
| litellm_config_path | Path to the LiteLLM config file | container/config/litellm_config.yaml |
| environment | Environment name | dev |
| on_premises_cidr_blocks | List of CIDR blocks for your on-premises network | [] |

### Custom Configuration

You can customize the LiteLLM configuration by modifying the `container/config/litellm_config.yaml` file. This file is used to configure the LiteLLM proxy server, including model providers, routing strategies, and other settings.

### Configuration Management

This project uses the official `ghcr.io/berriai/litellm:main-stable` image directly and manages configuration in a cloud-native way using AWS Systems Manager Parameter Store:

1. **YAML Configuration in Parameter Store**: The LiteLLM configuration is stored as a YAML string in AWS Systems Manager Parameter Store. This approach offers several benefits:
   - **Centralized Configuration**: All configuration is stored in a central location
   - **Version Control**: Parameter Store supports versioning of parameters
   - **Secure**: Sensitive configuration can be encrypted using KMS
   - **No Custom Image Required**: No need to build a custom Docker image for configuration changes

2. **Container Startup Process**:
   ```bash
   # Fetch configuration from Parameter Store
   aws ssm get-parameter --name /litellm-xyz123/litellm/config --region us-east-1 --query Parameter.Value --output text > /tmp/litellm_config.yaml
   
   # Start LiteLLM with the fetched configuration
   litellm --config /tmp/litellm_config.yaml --port 4000 --host 0.0.0.0
   ```

3. **Updating Configuration**: To update the LiteLLM configuration:
   - Modify the `container/config/litellm_config.yaml` file
   - Run `terraform apply` to update the Parameter Store parameter
   - The changes will be applied when new tasks are launched

4. **Handling API Keys**: For API keys referenced in the configuration file:
   - Store API keys in AWS Secrets Manager
   - Use AWS Secrets Manager references in your configuration
   - Example:
     ```yaml
     model_list:
       - model_name: "gpt-4o"
         litellm_params:
           model: "openai/gpt-4o"
           api_key: "{{resolve:secretsmanager:your-secret-name:SecretString:OPENAI_API_KEY}}"
     ```
   - Alternatively, you can use AWS Parameter Store for API keys:
     ```yaml
     model_list:
       - model_name: "gpt-4o"
         litellm_params:
           model: "openai/gpt-4o"
           api_key: "{{resolve:ssm:/path/to/api-key:1}}"
     ```

5. **Custom Image**: If you need a custom image with specific dependencies, you can create your own image based on the official one:
   ```Dockerfile
   FROM ghcr.io/berriai/litellm:main-stable
   # Add your customizations here
   ```

## Deployment Script

The project includes a deployment script (`deploy.sh`) that provides the following commands:

- `./deploy.sh` - Deploy the infrastructure
- `./deploy.sh -destroy` - Destroy the infrastructure

## Outputs

| Name | Description |
|------|-------------|
| load_balancer_dns | DNS name of the load balancer |
| litellm_endpoint | Endpoint URL for the LiteLLM proxy (internal ALB) |
| access_instructions | Instructions for accessing the service |
| database_endpoint | Endpoint of the Aurora database |
| database_port | Port of the Aurora database |
| database_reader_endpoint | Reader endpoint of the Aurora database |
| vpc_id | ID of the VPC |
| private_subnets | IDs of the private subnets |
| public_subnets | IDs of the public subnets |
| database_subnets | IDs of the database subnets |
| ecs_cluster_id | ID of the ECS cluster |
| ecs_cluster_name | Name of the ECS cluster |
| ecr_repository_url | URL of the ECR repository |
| ecr_image_uri | URI of the Docker image in ECR |

## Security Considerations

- The database is deployed in private subnets and is not accessible from the internet
- The Fargate service is deployed in private subnets and is only accessible through the internal ALB
- The internal Application Load Balancer is only accessible from within the VPC and from specified on-premises networks
- Security groups restrict access to the ALB based on CIDR blocks
- Database credentials are stored in AWS Secrets Manager
- The LiteLLM configuration is stored in AWS Systems Manager Parameter Store

## Network Access Control

This deployment uses an internal Application Load Balancer with security groups to control access to the LiteLLM proxy:

1. **Internal ALB**: The Application Load Balancer is deployed as an internal load balancer in private subnets, making it inaccessible from the public internet.

2. **Security Group Access Control**: Access to the ALB is controlled by security groups that allow traffic only from:
   - Within the VPC (for internal services)
   - Specified on-premises networks (via the `on_premises_cidr_blocks` variable)

3. **Network-Level Security**: This approach provides network-level security without requiring user authentication, making it suitable for API services.

To configure network access control:

1. Set the `on_premises_cidr_blocks` variable to a list of CIDR blocks for your on-premises networks that should have access to the LiteLLM proxy.

Example configuration in `terraform.tfvars`:

```hcl
on_premises_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]  # Your on-premises networks
```

## VPN Access (Optional)

For secure access from on-premises networks, you can set up a VPN connection to your AWS VPC using AWS Site-to-Site VPN or AWS Client VPN. This is not included in this Terraform configuration but can be added as needed.

## API Authentication

While this deployment provides network-level security through the internal ALB and security groups, you may want to add API-level authentication for additional security. This can be done by configuring API keys in the LiteLLM configuration:

```yaml
api_key:
  my_api_key: sk_my_api_key_here
```

## Health Check Implementation

The project includes dedicated health check endpoints for better container monitoring and reliability:

1. **Dedicated Health Check Endpoints**:
   - `/health/readiness`: Verifies if the service is ready to accept traffic
   - `/health/liveliness`: Confirms the service is running properly

2. **ALB Health Check Configuration**:
   - The ALB target group is configured to use the `/health/liveliness` endpoint
   - Customizable health check parameters (interval, timeout, healthy threshold, etc.)

3. **Container Health Check**:
   - The ECS task definition includes a health check command that verifies the service is healthy
   - Automatically replaces unhealthy containers

## S3 Bucket Logging

The project implements comprehensive logging with S3 bucket storage:

1. **ALB Access Logs**:
   - All ALB access logs are stored in a dedicated S3 bucket
   - Logs are encrypted using server-side encryption (AES-256)
   - Proper bucket policies for log delivery

2. **Log Retention**:
   - Configurable log retention policies
   - Automatic log rotation

3. **Security**:
   - Bucket is configured with appropriate access controls
   - Public access is blocked

## WAF Protection

The project includes AWS WAF integration for enhanced security:

1. **Rate Limiting**:
   - Limits requests to 1000 per 5 minutes per IP address
   - Prevents abuse and DoS attacks

2. **AWS Managed Rules**:
   - Implements AWS Managed Rules Common Rule Set
   - Protection against common web exploits (SQL injection, XSS, etc.)

3. **WAF Association**:
   - WAF is associated with the Application Load Balancer
   - All traffic to the LiteLLM proxy is inspected and filtered

## Improvements in This Version

This version of the project has been enhanced with several improvements:

1. **Internal ALB with Security Groups**: Replaced Cognito authentication with an internal ALB and security group access control
2. **VPC Module**: Uses terraform-aws-modules/vpc/aws for networking infrastructure
3. **ECS Module**: Uses terraform-aws-modules/ecs/aws for the ECS cluster
4. **Direct Aurora Resources**: Uses AWS RDS resources directly for the Aurora PostgreSQL database
5. **Simplified Structure**: Removed custom modules in favor of standard modules and direct resources
6. **Enhanced Outputs**: Added more useful outputs for better visibility into the deployed resources
7. **Health Check Implementation**: Added dedicated health check endpoints for better container monitoring
8. **S3 Bucket Logging**: Implemented ALB access logs stored in S3 with proper encryption and policies
9. **WAF Protection**: Added AWS WAF with rate limiting and protection against common web exploits
10. **Enhanced Monitoring**: Extended CloudWatch log retention to 90 days
11. **Improved Auto-scaling**: Separate CPU and memory-based auto-scaling policies

## License

This project is licensed under the MIT License - see the LICENSE file for details.
