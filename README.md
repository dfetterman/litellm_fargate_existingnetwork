# LiteLLM on AWS Fargate with Terraform (Modular)

This project deploys LiteLLM on AWS Fargate using Terraform with a modular structure and standard AWS modules. It provides a scalable, serverless infrastructure for running the LiteLLM proxy server.

## Architecture

The architecture consists of:

- VPC with public, private, and database subnets (using terraform-aws-modules/vpc/aws)
- Aurora PostgreSQL Serverless v2 database for storing configuration and usage data
- ECS Fargate service running the LiteLLM container (using terraform-aws-modules/ecs/aws)
- Application Load Balancer for routing traffic
- Auto-scaling based on CPU and memory utilization
- CloudWatch for logs and monitoring
- AWS Secrets Manager for secure credential management

## Project Structure

The project is organized into modules:

```
litellm-aws-fargate/
├── main.tf                # Main configuration file
├── variables.tf           # Input variables
├── outputs.tf             # Output values
├── modules/
│   ├── networking/        # VPC and security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/          # Aurora PostgreSQL database
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── fargate/           # ECS Fargate service
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── config/                # LiteLLM configuration files
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
container_image = "ghcr.io/berriai/litellm:main-stable"
```

3. Run the management script to deploy:

```bash
./manage.sh deploy
```

4. After the deployment is complete, you can access the LiteLLM proxy server at the URL provided in the outputs.

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
| container_image | Docker image for the LiteLLM container | ghcr.io/berriai/litellm:main-stable |
| container_port | Port the container listens on | 4000 |
| cpu | CPU units for the Fargate task | 1024 (1 vCPU) |
| memory | Memory for the Fargate task in MiB | 2048 (2 GB) |
| desired_count | Desired number of tasks | 1 |
| max_capacity | Maximum number of tasks for autoscaling | 2 |
| litellm_config_path | Path to the LiteLLM config file | config/litellm_config.yaml |
| environment | Environment name | dev |

### Custom Configuration

You can customize the LiteLLM configuration by modifying the `config/litellm_config.yaml` file. This file is used to configure the LiteLLM proxy server, including model providers, routing strategies, and other settings.

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
   - Modify the `config/litellm_config.yaml` file
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

## Management Script

The project includes a unified management script (`manage.sh`) that provides the following commands:

- `./manage.sh deploy` - Deploy the infrastructure
- `./manage.sh update` - Update the existing deployment
- `./manage.sh destroy` - Destroy the infrastructure

## Outputs

| Name | Description |
|------|-------------|
| load_balancer_dns | DNS name of the load balancer |
| litellm_endpoint | Endpoint URL for the LiteLLM proxy |
| database_endpoint | Endpoint of the Aurora database |
| database_port | Port of the Aurora database |
| database_reader_endpoint | Reader endpoint of the Aurora database |
| vpc_id | ID of the VPC |
| private_subnets | IDs of the private subnets |
| public_subnets | IDs of the public subnets |
| database_subnets | IDs of the database subnets |
| ecs_cluster_id | ID of the ECS cluster |
| ecs_cluster_name | Name of the ECS cluster |

## Security Considerations

- The database is deployed in private subnets and is not accessible from the internet
- The Fargate service is deployed in private subnets and is only accessible through the load balancer
- Security groups are configured to restrict access to the minimum required ports
- Database credentials are stored in AWS Secrets Manager
- The load balancer is configured to use HTTP, but you can modify the configuration to use HTTPS with an SSL certificate

## Improvements in This Version

This version of the project has been simplified by using standard Terraform AWS modules:

1. **VPC Module**: Uses terraform-aws-modules/vpc/aws for networking infrastructure
2. **ECS Module**: Uses terraform-aws-modules/ecs/aws for the ECS cluster
3. **Direct Aurora Resources**: Uses AWS RDS resources directly for the Aurora PostgreSQL database
4. **Simplified Structure**: Removed custom modules in favor of standard modules and direct resources
5. **Enhanced Outputs**: Added more useful outputs for better visibility into the deployed resources

## License

This project is licensed under the MIT License - see the LICENSE file for details.
