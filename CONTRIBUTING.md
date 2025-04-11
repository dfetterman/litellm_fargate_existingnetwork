# Contributing to LiteLLM on AWS Fargate

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please be respectful and considerate of others when contributing to this project. We aim to foster an inclusive and welcoming community.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion for improvement:

1. Check if the issue already exists in the [GitHub Issues](https://github.com/yourusername/litellm-aws-fargate/issues)
2. If not, create a new issue with a descriptive title and detailed description
3. Include steps to reproduce the issue, expected behavior, and actual behavior
4. Add relevant screenshots or logs if applicable

### Submitting Changes

1. Fork the repository
2. Create a new branch from `main` for your changes
3. Make your changes following the coding standards
4. Write or update tests as necessary
5. Update documentation to reflect your changes
6. Commit your changes with clear, descriptive commit messages
7. Push your branch to your fork
8. Submit a pull request to the `main` branch

### Pull Request Process

1. Ensure your code follows the project's coding standards
2. Update the README.md or other documentation with details of changes if appropriate
3. The pull request will be reviewed by maintainers
4. Address any feedback or requested changes
5. Once approved, your pull request will be merged

## Development Setup

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed (version 1.0.0 or later)
- OpenVPN client for testing VPN connectivity
- Basic understanding of AWS services and Terraform

### Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/litellm-aws-fargate.git
   cd litellm-aws-fargate
   ```

2. Create a `terraform.tfvars` file with your development settings:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your settings
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Make your changes to the Terraform code

5. Format and validate your changes:
   ```bash
   terraform fmt
   terraform validate
   ```

6. Test your changes (if possible in a development AWS account)

## Coding Standards

### Terraform

- Use consistent indentation (2 spaces)
- Use snake_case for resource names and variable names
- Group related resources together
- Use descriptive names for resources, variables, and outputs
- Add comments for complex configurations
- Use modules for reusable components
- Follow Terraform best practices

### Documentation

- Keep documentation up to date with code changes
- Use clear, concise language
- Include examples where appropriate
- Use proper Markdown formatting

## License

By contributing to this project, you agree that your contributions will be licensed under the project's [MIT License](LICENSE).
