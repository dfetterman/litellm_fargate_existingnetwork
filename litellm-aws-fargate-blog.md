# From 429 to 200: How Implementing an AI Gateway Can Enable Your Production Workloads

## Scaling LLM Applications with LiteLLM on AWS Fargate

LiteLLM provides a unified interface for accessing over 100 different language models while presenting a standardized OpenAI-compatible API. This means your applications can work with various model providers without significant code changes, making it an indispensable tool for organizations looking to build robust AI services.

Have you ever hit that dreaded "429 Too Many Requests" error when working with large language models (LLMs)? If so, you're not alone. As AI applications become more prevalent in production environments, managing rate limits and scaling LLM deployments has become a significant challenge for many organizations. In this post, I'll show you how to overcome these limitations by building a robust, scalable LLM infrastructure using LiteLLM Proxy on AWS Fargate.

We'll explore a powerful architecture that leverages LiteLLM Proxy to distribute load across multiple AWS accounts, effectively solving the rate limit puzzle. I'll walk you through setting up this system, connecting it to AWS Bedrock, and implementing a smart load-balancing strategy to keep your AI applications running smoothly, even under heavy load.

## The Rate Limiting Challenge

### Handling High-Traffic AI Applications

Let's consider a real-world scenario where this architecture proves invaluable. Imagine you're building an AI-powered customer service application that needs to handle thousands of concurrent user queries. Each query requires a call to Claude on AWS Bedrock, but you're limited by the default quota of 5 requests per second per account.

With our multi-account LiteLLM setup, you can:

1. Distribute load across 5 AWS accounts, effectively increasing your quota to 25 requests per second
2. Implement intelligent routing to ensure optimal utilization of each account's quota
3. Set up automatic fallbacks to handle rate limit errors gracefully
4. Monitor usage patterns and adjust your infrastructure accordingly

The result? A robust, scalable AI application that can handle high traffic without disruption, providing a seamless experience for your users.

When working with LLM providers, you'll inevitably run into rate limits, which manifest as HTTP 429 "Too Many Requests" errors. These limits can come in various flavors:

- **Token rate limits** (TPM - tokens per minute)
- **Request rate limits** (RPM - requests per minute)
- **Concurrent request limits**

For high-throughput applications or those serving numerous users, these limits can quickly become a bottleneck. This is particularly true for AWS Bedrock, which applies quotas at the account level rather than the model level.

Consider this scenario: Your application needs to handle 100 requests per minute, but your AWS Bedrock account has a quota of only 50 RPM for Claude models. Without a solution to manage these limits, your application will experience frequent failures, leading to poor user experience and potential business impact.

## Why AI Gateway and LiteLLM

Before diving into the implementation details, let's understand what makes LiteLLM so valuable. Think of LiteLLM as the Swiss Army knife for LLM APIs. It's an open-source tool that acts as a unified interface for accessing over 100 different language models from providers like OpenAI, Anthropic, Cohere, and AWS Bedrock.

LiteLLM offers two main modes of operation:

1. **As an SDK** for direct code integration
2. **As a proxy server** that presents a single OpenAI-compatible API

For enterprise deployments, the proxy mode is where the magic happens. It provides:

- **Centralized management** of API calls to various LLM providers
- **Flexibility** to switch between models without code changes
- **Advanced routing capabilities** for handling quotas and load balancing
- **Comprehensive logging and monitoring** for performance tracking and cost management

The best part? LiteLLM Proxy presents an OpenAI-compatible endpoint, meaning any application built for OpenAI's API can work with LiteLLM with minimal changes. This is a game-changer for teams looking to standardize their LLM infrastructure.

## Architecture Overview

To tackle this challenge head-on, we'll deploy LiteLLM Proxy on AWS Fargate and connect it to multiple AWS Bedrock accounts. This architecture includes:

- **AWS Fargate** for hosting and scaling LiteLLM Proxy containers
- **Cross-account IAM roles** to optimize AWS Bedrock quota usage
- **Amazon Aurora PostgreSQL** for storing configuration and usage data
- **CloudWatch** for monitoring and logging
- **AWS Application Load Balancer** for distributing incoming traffic
- **AWS Client VPN** for secure access to the service

![LiteLLM AWS Architecture](https://raw.githubusercontent.com/sofianhamiti/litellm-aws-fargate/main/docs/images/litellm-aws-architecture.png)

This setup enables intelligent routing of requests across multiple AWS accounts, effectively multiplying your available quotas. Let's break down the implementation step by step.

## Hosting a LiteLLM AI Gateway with Fargate

Our architecture places the LiteLLM service in a private subnet with no direct internet access. This security-first approach ensures that your LLM proxy is not exposed to the public internet, reducing the attack surface. Access to the service is provided through AWS Client VPN, which uses certificate-based authentication for secure connections.

The architecture consists of the following components:

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

## Launching the Example AI Gateway Stack

To make the deployment process reproducible and manageable, we'll use Terraform to provision our infrastructure. The [litellm-aws-fargate](https://github.com/sofianhamiti/litellm-aws-fargate) repository contains all the necessary Terraform code to deploy this architecture.

First, clone the repository:

```bash
git clone https://github.com/sofianhamiti/litellm-aws-fargate.git
cd litellm-aws-fargate
```

Next, create a `terraform.tfvars` file with your specific configuration:

```hcl
aws_region           = "us-east-1"
project_name         = "litellm"
environment          = "dev"
vpn_certificate_arn  = "arn:aws:acm:region:account:certificate/certificate-id"
```

Initialize Terraform and apply the configuration:

```bash
terraform init
terraform plan
terraform apply
```

After successful deployment, note the outputs:
- `client_vpn_endpoint_dns_name`
- `client_vpn_self_service_portal_url`
- `litellm_internal_endpoint`
- `litellm_master_key`

## Connecting Your AI Gateway to Bedrock

Now comes the exciting part - connecting LiteLLM to AWS Bedrock across multiple accounts. The key here is to use IAM roles for secure access without handling credentials in your application.

The LiteLLM configuration file (`litellm_config.yaml`) defines your model deployments and routing strategy.

### LiteLLM Configuration for AWS Bedrock

Here's an example configuration that connects to AWS Bedrock across multiple accounts:

```yaml
# General application settings
general_settings:
  store_prompts_in_spend_logs: true
  master_key: os.environ/LITELLM_MASTER_KEY
  salt_key: os.environ/LITELLM_SALT_KEY
  database_url: os.environ/DATABASE_URL
  store_model_in_db: true
  disable_spend_logs: true

# LiteLLM specific settings
litellm_settings:
  turn_off_message_logging: true
  global_disable_no_log_param: true

# Define common model parameters
model_defaults: &model_defaults
  model: "bedrock/us.anthropic.claude-3-7-sonnet-20250219-v1:0"
  tpm: 20000
  rpm: 5
  aws_region_name: os.environ/AWS_REGION

# Model configuration
model_list:
  - model_name: "claude-3-7-load-balance"
    litellm_params:
      <<: *model_defaults
      # Default IAM role from container, using this account inference profile
      
  # Add entries for each account that can be assumed
  - model_name: "claude-3-7-load-balance"
    litellm_params:
      <<: *model_defaults
      aws_session_name: "bedrock-account-1"
      aws_role_name: "arn:aws:iam::111111111111:role/bedrock-caller"

  - model_name: "claude-3-7-load-balance"
    litellm_params:
      <<: *model_defaults
      aws_session_name: "bedrock-account-2"
      aws_role_name: "arn:aws:iam::222222222222:role/bedrock-caller"

  - model_name: "claude-3-7-load-balance"
    litellm_params:
      <<: *model_defaults
      aws_session_name: "bedrock-account-3"
      aws_role_name: "arn:aws:iam::333333333333:role/bedrock-caller"

# Router configuration
router_settings:
  routing_strategy: "least-busy"
  health_check_interval: 30
  timeout: 45
  retries: 3
  retry_after: 5
```

This configuration defines multiple instances of the same model (`claude-3-7-load-balance`), each pointing to a different AWS account through role assumption. The router settings specify a "least-busy" routing strategy, which will distribute requests to the model instance with the fewest active requests.

## Spreading Load Across Multiple AWS Accounts

Now for the pièce de résistance - using LiteLLM's routing capabilities to distribute load across multiple AWS accounts, effectively multiplying your available quotas.

LiteLLM Proxy offers several routing strategies, but for our multi-account strategy, the "Least Busy" approach works exceptionally well. It monitors the number of active requests per model and routes new requests to the model with the fewest active requests, ensuring optimal distribution across accounts.

![Load Balancing Diagram](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*JKH8FVL5WGZphnT7zzuXzg.png)

To handle rate limits gracefully, we can configure fallbacks in our `litellm_config.yaml`. When a model returns a 429 error, LiteLLM will automatically retry the request with the next model in the fallback chain:

```yaml
router_settings:
  routing_strategy: least-busy
  fallbacks: [
    {
      "claude-3-7-load-balance": ["claude-3-7-load-balance-account2", "claude-3-7-load-balance-account3"]
    }
  ]
```

This configuration will first try `claude-3-7-load-balance` in the primary account, then fall back to the same model in the second account if rate limited, and finally try the third account as a last resort.

### Setting Up Cross-Account IAM Roles

For each AWS account you'll use, create a role that allows the LiteLLM proxy to assume it and access Bedrock:

1. Create a trust policy document:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::MAIN_ACCOUNT_ID:role/LiteLLMTaskRole"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

2. Create a permission policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "*"
    }
  ]
}
```

3. Create the role in each account and attach the policies.

## Using Your LiteLLM Gateway

Once deployed, you can call the LiteLLM Proxy using standard OpenAI-compatible API calls. First, connect to the VPN to access the internal endpoint, then use the following code:

Using curl:

```bash
curl -X POST "http://<litellm_internal_endpoint>/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your_litellm_key" \
  -d '{
    "model": "claude-3-7-load-balance",
    "messages": [
      {"role": "user", "content": "Explain quantum computing in simple terms"}
    ]
  }'
```

Using Python:

```python
from openai import OpenAI

client = OpenAI(
    api_key="your_litellm_key",
    base_url="http://<litellm_internal_endpoint>"
)

response = client.chat.completions.create(
    model="claude-3-7-load-balance",
    messages=[
        {"role": "user", "content": "Explain quantum computing in simple terms"}
    ]
)

print(response.choices[0].message.content)
```

Behind the scenes, LiteLLM Proxy will intelligently route this request to one of your configured model deployments across multiple accounts, using the least busy strategy to avoid rate limits.

## Security Considerations

For production deployments, consider these security best practices:

- Deploy LiteLLM in private subnets with no direct internet access
- Use AWS Client VPN for secure access to the internal Application Load Balancer
- Implement strong authentication with API keys
- Restrict IAM roles to the minimum required permissions
- Enable encryption in transit and at rest

Our architecture already implements many of these best practices:

1. **Private Subnet Isolation**: LiteLLM runs in a private subnet with no direct internet access
2. **VPN Access**: All access to the service is through an encrypted VPN tunnel
3. **Certificate-based Authentication**: Client VPN uses certificates for authentication
4. **Encrypted Database**: Aurora PostgreSQL encrypts data at rest
5. **IAM Role Separation**: Different IAM roles for different components
6. **No Hardcoded Secrets**: Sensitive values are generated or provided at deployment time

## Conclusion

Implementing LiteLLM Proxy on AWS Fargate with a multi-account strategy provides a robust solution for organizations facing LLM rate limiting challenges. This architecture delivers several key benefits:

- **Increased throughput** by leveraging quotas across multiple AWS accounts
- **Enhanced reliability** through intelligent routing and fallbacks
- **Simplified API management** with a standardized OpenAI-compatible interface
- **Improved observability** with comprehensive logging and monitoring

As LLMs continue to become critical components of modern applications, managing their scalability becomes paramount. LiteLLM Proxy provides the flexibility and robustness needed to handle enterprise-scale deployments while mitigating the limitations imposed by individual providers.

By following the implementation steps outlined in this post, you can build a solution that scales with your organization's needs and ensures consistent, reliable access to LLM capabilities, no matter how much your demand grows.

For a complete implementation example, refer to the GitHub repository at [https://github.com/sofianhamiti/litellm-aws-fargate](https://github.com/sofianhamiti/litellm-aws-fargate), which provides detailed code and configuration for deploying LiteLLM on AWS Fargate with a security-first approach.
