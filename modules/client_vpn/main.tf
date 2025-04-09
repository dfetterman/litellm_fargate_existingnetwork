# Security group for the Client VPN endpoint
resource "aws_security_group" "client_vpn" {
  name        = "${var.name}-client-vpn-sg"
  description = "Security group for Client VPN endpoint"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  # Specific egress rules for ALB access
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow HTTP access to ALB"
  }

  egress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow port 4000 access to ALB"
  }

  tags = merge(var.tags, { Name = "${var.name}-client-vpn-sg" })
}

# Client VPN endpoint
resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = "${var.name} Client VPN endpoint"
  server_certificate_arn = var.server_certificate_arn
  client_cidr_block      = var.client_cidr_block
  
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_certificate_arn
  }
  
  connection_log_options {
    enabled = false
  }

  # Enable split-tunnel mode to only route traffic to VPC through the VPN
  split_tunnel = true

  # Enable self-service portal for client configuration download
  self_service_portal = "enabled"

  # Use AWS provided DNS (empty list means use AWS DNS)
  dns_servers = []

  # VPN port (default is 443)
  vpn_port = 443

  # Apply tags
  tags = merge(var.tags, { Name = "${var.name}-client-vpn" })
}

# Associate the Client VPN endpoint with the first private subnet
resource "aws_ec2_client_vpn_network_association" "this" {
  count                  = length(var.private_subnets)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = var.private_subnets[count.index]
  
  timeouts {
    create = "10m"
  }
}

# Authorization rule to allow access to the VPC CIDR
resource "aws_ec2_client_vpn_authorization_rule" "vpc_access" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = var.vpc_cidr
  authorize_all_groups   = true
  description            = "Allow access to VPC resources"
}

# Authorization rule to allow internet access (optional)
resource "aws_ec2_client_vpn_authorization_rule" "internet_access" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
  description            = "Allow internet access"
}
