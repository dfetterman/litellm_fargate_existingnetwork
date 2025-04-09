# Security Considerations for LiteLLM on AWS Fargate

This document outlines the security considerations and best practices for the LiteLLM AWS Fargate deployment.

## Architecture Security Features

The deployment architecture includes several security features:

1. **Private Subnet Isolation**: LiteLLM runs in a private subnet with no direct internet access
2. **VPN Access**: All access to the service is through an encrypted VPN tunnel
3. **Certificate-based Authentication**: Client VPN uses certificates for authentication
4. **Encrypted Database**: Aurora PostgreSQL encrypts data at rest
5. **IAM Role Separation**: Different IAM roles for different components
6. **No Hardcoded Secrets**: Sensitive values are generated or provided at deployment time

## Network Security

### VPC and Subnet Design

- The VPC is configured with public and private subnets
- LiteLLM containers run only in private subnets
- NAT Gateways in public subnets provide outbound internet access for containers
- No direct inbound access from the internet to the containers

### Security Groups

The deployment uses multiple security groups to control traffic:

1. **ALB Security Group**:
   - Allows inbound traffic only from the VPN CIDR range
   - Allows outbound traffic only to the ECS tasks security group

2. **ECS Tasks Security Group**:
   - Allows inbound traffic only from the ALB security group
   - Allows outbound traffic to the database and the internet (for API calls)

3. **Database Security Group**:
   - Allows inbound traffic only from the ECS tasks security group
   - No outbound traffic allowed

### Client VPN

- Uses certificate-based authentication
- Encrypts all traffic between clients and the VPN endpoint
- Restricts access to the VPC CIDR range
- Logs all connection attempts and session activity

## Data Security

### Data at Rest

- Aurora PostgreSQL database is encrypted at rest using AWS KMS
- S3 bucket for logs is encrypted at rest
- EBS volumes used by Fargate tasks are encrypted

### Data in Transit

- All traffic between the client and the VPN endpoint is encrypted
- All traffic between the VPN endpoint and the ALB is encrypted
- Database connections can be encrypted using SSL/TLS

### Sensitive Data Handling

- LiteLLM master key and salt key are generated securely during deployment
- Database password is generated securely if not provided
- Sensitive outputs are marked as sensitive in Terraform
- No sensitive data is logged or exposed in plaintext

## Identity and Access Management

### IAM Roles

The deployment uses the principle of least privilege with separate IAM roles:

1. **Task Execution Role**:
   - Allows pulling container images from ECR
   - Allows writing logs to CloudWatch
   - Allows reading environment variables from SSM Parameter Store

2. **Task Role**:
   - Allows assuming roles in other AWS accounts for Bedrock access
   - Allows reading and writing to the database
   - Allows making API calls to AWS services as needed

### Authentication and Authorization

- Client VPN uses certificate-based authentication
- LiteLLM uses API keys for authentication
- LiteLLM supports team-based authorization for API keys

## Monitoring and Logging

### CloudWatch Logs

- Container logs are sent to CloudWatch Logs
- VPN connection logs are sent to CloudWatch Logs
- ALB access logs are sent to S3

### CloudWatch Metrics

- Container metrics (CPU, memory, etc.) are sent to CloudWatch
- ALB metrics (requests, errors, etc.) are sent to CloudWatch
- Database metrics are sent to CloudWatch

## Security Best Practices

### Recommended Additional Security Measures

1. **Enable AWS WAF** for the internal ALB:
   ```hcl
   resource "aws_wafv2_web_acl_association" "alb" {
     resource_arn = module.networking.alb_arn
     web_acl_arn  = aws_wafv2_web_acl.main.arn
   }
   
   resource "aws_wafv2_web_acl" "main" {
     name        = "${var.project_name}-web-acl"
     description = "WAF for LiteLLM ALB"
     scope       = "REGIONAL"
     
     # Add rules for common web exploits
     # ...
   }
   ```

2. **Implement AWS CloudTrail** to monitor API calls:
   ```hcl
   resource "aws_cloudtrail" "main" {
     name                          = "${var.project_name}-cloudtrail"
     s3_bucket_name                = aws_s3_bucket.cloudtrail.id
     include_global_service_events = true
     is_multi_region_trail         = false
     enable_logging                = true
   }
   ```

3. **Use AWS Config** to monitor and enforce security policies:
   ```hcl
   resource "aws_config_configuration_recorder" "main" {
     name     = "${var.project_name}-config-recorder"
     role_arn = aws_iam_role.config.arn
     
     recording_group {
       all_supported                 = true
       include_global_resource_types = true
     }
   }
   ```

4. **Enable GuardDuty** for threat detection:
   ```hcl
   resource "aws_guardduty_detector" "main" {
     enable = true
   }
   ```

5. **Implement AWS Security Hub** for security posture management:
   ```hcl
   resource "aws_securityhub_account" "main" {}
   ```

### Regular Security Tasks

1. **Rotate API keys** regularly:
   - LiteLLM API keys
   - LLM provider API keys
   - AWS access keys

2. **Update container images** with security patches:
   - Rebuild and deploy container images regularly
   - Use automated vulnerability scanning

3. **Review security groups and IAM roles** periodically:
   - Remove unnecessary permissions
   - Follow the principle of least privilege

4. **Monitor CloudWatch Logs** for suspicious activity:
   - Set up CloudWatch Alarms for security events
   - Use CloudWatch Logs Insights for analysis

## Production Deployment Recommendations

For production deployments, consider these additional security measures:

1. **Multi-factor authentication** for AWS Console access
2. **VPC Flow Logs** to monitor network traffic
3. **AWS Shield** for DDoS protection
4. **AWS KMS** for managing encryption keys
5. **AWS Secrets Manager** for storing and rotating secrets
6. **AWS Private Link** for private connectivity to AWS services
7. **AWS Network Firewall** for additional network protection
8. **AWS IAM Access Analyzer** to identify unintended access
9. **AWS Systems Manager Session Manager** for secure instance access
10. **AWS Certificate Manager** for managing SSL/TLS certificates

## Compliance Considerations

Depending on your regulatory requirements, you may need to implement additional controls:

1. **HIPAA** (Healthcare):
   - Business Associate Agreement (BAA) with AWS
   - Encryption of all PHI data
   - Comprehensive audit logging

2. **PCI DSS** (Payment Card Industry):
   - Network segmentation
   - Vulnerability scanning
   - Penetration testing

3. **GDPR** (European Union):
   - Data processing agreements
   - Data minimization
   - Right to erasure capabilities

4. **SOC 2** (Service Organizations):
   - Security monitoring
   - Change management
   - Incident response procedures

## Security Incident Response

In case of a security incident:

1. **Isolate** the affected resources
2. **Investigate** the root cause
3. **Remediate** the vulnerability
4. **Restore** from clean backups if necessary
5. **Document** the incident and response
6. **Improve** security controls to prevent similar incidents
