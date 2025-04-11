Example 1
5 Simple Steps to MLOps with GitHub Actions, MLflow, and SageMaker Pipelines
Kick-start your path to production with a project template


Earlier this year, I published a step-by-step guide to automating an end-to-end ML lifecycle with built-in SageMaker MLOps project templates and MLflow. It brought workflow orchestration, model registry, and CI/CD under one umbrella to reduce the effort of running end-to-end MLOps projects.


Photo by NASA on Unsplash
In this post, we will go a step further and define an MLOps project template based on GitHub, GitHub Actions, MLflow, and SageMaker Pipelines that you can reuse across multiple projects to accelerate your ML delivery.

We will take an example model trained using Random Forest on the California House Prices dataset, and automate its end-to-end lifecycle until deployment into a real-time inference service.

Walkthrough overview
We will tackle this in 4 steps:

We will first setup a development environment with IDE, MLflow tracking server, and connect GitHub Actions to your AWS account.
Second, I will show how you can experiment, and collaborate easily with your team members. We will also package code into containers, and run them in scalable SageMaker jobs.
Then, we will automate your model build workflow with a SageMaker Pipeline and schedule it to run once a week.
Finally, we will deploy a real-time inference service in your account with a GitHub Actions-based CI/CD pipeline.
Note: There can be more to MLOps than deploying inference services (e.g: data labeling, date versioning, model monitoring), and this template should give you enough structure to tailor it to your needs.

Prerequisites
To go through this example, make sure you have the following:

Visited Introducing Amazon SageMaker Pipelines if SageMaker Pipelines sound new to you.
Familiarity with MLOps with MLFlow and Amazon SageMaker Pipelines.
Familiarity with GitHub Actions. Github Actions — Everything You Need to Know to Get Started could be a good start if it sounds new to you.
This GitHub repository cloned into your environment.
Step 1: Setting up your project environment

Image by author: Architecture overview for the project.
We will use the following components in the project:

SageMaker for container-based jobs, model hosting, and ML pipelines
MLflow for experiment tracking and model registry.
API Gateway for exposing our inference endpoint behind an API.
GitHub as repo, CI/CD and ML pipeline scheduler with GitHub Actions.
If you work in an enterprise, this setup may be done for you by IT admins.

Working from your favourite IDE
For productivity, make sure you work from an IDE you are comfortable with. Here, I host VS Code on a SageMaker Notebook Instance and will also use SageMaker Studio to visualize the ML pipeline.


Image by author
See Host code-server on Amazon SageMaker for install instructions.

Setting up a central MLflow tracking server
We need a central MLflow tracking server to collaborate on experiments and register models. If you don’t have one, you can follow instructions and blog post to deploy the open source version of MLflow on AWS Fargate.


Image by author: Once deployed, make sure you keep the load balancer URI somewhere. We will use it in our project so code, jobs, and pipelines can talk to MLflow.
You can also swap MLflow for native SageMaker options, Weights & Biases, or any other tool of your choice.

Connecting GitHub Actions to your AWS account
Next, we will use OpenID Connect (OIDC) to allow GitHub Actions workflows to access resources in your account, without needing to store AWS credentials as long-lived GitHub secrets. See Configuring OpenID Connect in Amazon Web Services for instructions.



Image by author: We add the GitHub OIDC identity provider to IAM and configure an IAM role that will trust it.
You can setup a github-actions role with the following trust relationships:


We add SageMaker as principal so we can run jobs and pipelines directly from GitHub workflows. Equally so for Lambda and API Gateway.

For illustrative purposes, I attached the AdministratorAccess managed policy to the role. Make sure you tighten permissions in your environment.

Setting up GitHub repo secrets for the project
Finally, we store AWS account ID, region name, and github-actions role ARN as secrets in the GitHub repo. They can be sensitive information and will be used securely by your GitHub workflows. See Encrypted secrets for details.


Image by author: Make sure the secret names map to the names used in your workflows.
We are now ready to go!

Step 2: Experimenting and collaborating in your project
You can find the experiment folder in the repo with example notebooks and scripts. It is typically the place where you start the project and try to figure out approaches to your ML problem.

Below is the main notebook showing how to train a model with Random Forest on the California House Prices dataset, and do basic prediction:


It is a simple example to follow in our end-to-end project and you can run pip install -r requirements.txt to work with the same dependencies as your team members.

This experimental phase of the ML project can be fairly unstructured and you can decide with your team how you want to organize the sub-folders. Also, whether you should use notebooks or python scripts is totally up to you.

You can save local data and files in the data and model folders. I have added them to .gitignore so you don’t end up pushing big files to GitHub.

Structuring your repo for easy collaboration
You can structure your repo any way you want. Just keep in mind that ease of use and reproducibility are key for productivity in your project. So here I have put the whole project in a single repo and tried to find the balance between python project conventions and MLOps needs.

You can find bellow the folder structure with descriptions:


Tracking experiments with MLflow
You can track experiment runs with MLflow, whether you run code in your IDE or in SageMaker Jobs. Here, I log runs under the housing experiment.


Image by author
You can also find example labs in this repo for reference.

Step 3: Moving from local compute to container-based jobs in SageMaker
Running code locally can work in early project stages. However, at some point you will want to package dependencies into reproducible Docker images, and use SageMaker to run scalable, container-based jobs. I recommend reading A lift and shift approach for getting started with Amazon SageMaker if this sounds new to you.

Breaking down the workflow into jobs
You can breakdown your project workflow into steps. We split ours into 2: We run data processing in SageMaker Processing jobs, and model training in SageMaker Training jobs.


Image by author: The processing jobs will run and output a CSV file into S3. The file S3 location is then used when launching the training jobs.
Building containers and pushing them to ECR
The Dockerfiles for our jobs are in the docker folder and you can run the following shell command to push the images to ECR.

sh scripts/build_and_push.sh <ecr-repo-name> <dockerfile-folder>
Using configuration files in the project
To prevent hardcoding, we need a place to hold our jobs’ parameters. Those parameters can include container image URIs, MLflow tracking server URI, entry point script location, instance types, hyperparameters to use in your code running in SageMaker jobs.

We will use model_build.yaml for this. Its YAML structure makes it easy to extend and maintain over time. Make sure to add your MLflow server URI and freshly pushed container image URIs to the config before running jobs.

Running containerized jobs in SageMaker
You are now ready to execute run_job.py and run your code in SageMaker jobs. It will read the config and use code from src/model_build to launch the Processing and Training jobs.

SageMaker will inject prepare.py and train.py at run time into their respective containers, and use them as entry point.

Step 4: Automating your model building
So you have successfully experimented locally and ran workflow steps as container-based jobs in SageMaker. Now you can automate this process. Let’s call it the model_build process, as it relates to everything happening before model versions are registered into MLflow.

We want to automate the container image building, tie our ML workflow steps into a pipeline, and automate the pipeline creation into SageMaker. We will also schedule the pipeline executions.

Building container images automatically with GitHub workflows
In the previous step, we pushed container images to ECR with a script, and ran them in SageMaker jobs. Moving into automation, we use this GitHub workflow to handle the process for us.


Image by author
The workflow looks at Dockerfiles in the docker folder and triggers when changes occur in the repo main branch. Under the hood it uses a composite GitHub action that takes care of logging in into ECR, building, and pushing the images.

The workflow also tags the container images based on the GitHub commit to ensure traceability and reproducibility of your ML workflow steps.

Tying our ML workflow steps into a pipeline in SageMaker
Next, we define a pipeline in SageMaker to run our workflow steps. You can find our pipeline in the src/model_build folder. It basically runs the processing step, get its output data location, and trigger a training step. And same as for jobs, the pipeline executions use parameters defined in our model_build.yaml.

I have added scripts/submit_pipeline.py in the repo to help you create/update the pipeline in SageMaker on-demand. It can help debug and run the pipeline in SageMaker when needed.


Image by author: You can see your updated pipeline in SageMaker Studio and can run executions with the submit_pipeline.py --execute command.
Once happy with the pipeline, we automate its management using the update-pipeline GitHub workflow. It looks for pipeline changes in the main branch and runs submit_pipeline to create/update.

Scheduling our SageMaker Pipeline with GitHub Actions
We can apply different triggers to the pipeline, and here we will schedule its executions with the schedule-pipeline GitHub workflow. It uses a cron expression to run the pipeline at 12:00 on Fridays.

This basic scheduling example can work for some of your use cases and feel free to adjust pipeline triggers as you see fit. You may also want to point the model_build configuration to a place where new data comes in.


Image by author
After each pipeline execution you will see a new model version appear in MLflow. Those are model versions we want to deploy into production.

Step 5: Deploying your inference service into production
Now that we have model versions regularly coming into the model registry, we can deploy them into production. This is the model_deploy process.

Our real-time inference service
We will build a real-time inference service for our project. For this, we want to get model artifacts from the model registry, build an MLflow inference container, and deploy them into a SageMaker endpoint. We will expose our endpoint via a Lambda function and API that a client can call for predictions.


Image by author
In case you need to run predictions in batch, you can build an ML inference pipeline using the same approach as we took for model_build.

Pushing the inference container image to ECR
Alongside the ML model, we need a container image to handle the inference in our SageMaker Endpoint. Let’s push the one provided by MLflow into ECR.

I have added to build-mlflow-image Github workflow to automate this, and it will run the mlflow sagemaker build-and-push-container command to do that.

Defining our API stack with CDK
We use CDK to deploy our inference infrastructure and define our stack in the model_deploy folder. app.py is our main stack file. You will see it read the model_deploy config and create SageMaker Endpoint, Lambda function as request proxy, and an API using API gateway.

Make sure you update your model_deploy config with container image and MLflow tracking server URIs before deploying.

Deploying into production with a multi-stage CI/CD pipeline
We use a Trunk Based approach to deploy our inference API into production. Essentially, we use a multi-stage GitHub workflow hooked to the repo main branch to build, test, and deploy our inference service.


Image by author
The CI/CD workflow is defined in deploy-inference and has 4 steps:

build reads a chosen model version binary from MLflow (defined in config), and uploads its model.tar.gz to S3. This is done by mlflow_handler, which also saves the model S3 location in AWS SSM for use in later CI/CD stages. The MLflow handler also transitions the model into Staging in the model registry.
deploy-staging deploys the CDK stack into staging so we can run tests on the API before going into production. The job uses a composite GitHub action I have built for deploying CDK templates into AWS.
test-api does basic testing of the inference service in Staging. It sends an example payload to the API and checks if the response status is OK. If OK, the MLflow handler will transition the model into Production in the model registry. Feel free to add more tests as you see fit.
deploy-prod deploys the CDK stack into production.


Images by author: Model stages will be transitioned in MLflow, as it progresses through the pipeline, and archived when a new version comes in.
Using your inference service
When your service is successfully deployed into production, you can navigate to the AWS CloudFormation console, look at the stack Outputs, and copy your API URL.


Image by author
You are now ready to call your inference API and can use the following example data point in the request body:


You can use tools like Postman to test the inference API from your computer:


Image by author: The API will return the predicted house price value in a few milliseconds.
Conclusion
In this post, I have shared with you an MLOps project template putting experiment tracking, workflow orchestration, model registry, and CI/CD under one umbrella. It’s key goal is to reduce the effort of running end-to-end MLOps projects and accelerate your delivery.

It uses GitHub, GitHub Actions, MLflow, and SageMaker Pipelines and you can reuse it across multiple projects.

To go further in your learnings, you can visit Awesome SageMaker and find in a single place, all the relevant and up-to-date resources needed for working with SageMaker.




Example 2
MLOps with MLFlow and Amazon SageMaker Pipelines
Step-by-step guide to using MLflow with SageMaker projects
Sofian Hamiti
TDS Archive
Sofian Hamiti

Published in
TDS Archive

·
6 min read
·
Jul 25, 2021
277


3





Earlier this year, I published a step-by-step guide to deploying MLflow on AWS Fargate, and using it with Amazon SageMaker. This can help streamline the experimental phase of an ML project.


Photo by Artur Kornakov on Unsplash
In this post, we will go a step further and automate an end-to-end ML lifecycle using MLflow and Amazon SageMaker Pipelines.

SageMaker Pipelines combines ML workflow orchestration, model registry, and CI/CD into one umbrella so you can quickly get your models into production.


Image by author
We will create an MLOps project for model building, training, and deployment to train an example Random Forest model and deploy it into a SageMaker Endpoint. We will update the modelBuild side of the project so it can log models into the MLflow model registry, and the modelDeploy side so it can ship them to production.

Walkthrough overview
We will tackle this in 3 steps:

We will first deploy MLflow on AWS and launch an MLOps project in SageMaker.
Then we will update the modelBuild pipeline so we can log models into our MLflow model registry.
Finally, I will show how you can deploy the MLflow models into production with the modelDeploy pipeline.
Below is the architecture overview for the project:


Image by author: Architecture overview
Prerequisites
To go through this example, make sure you have the following:

Visited Introducing Amazon SageMaker Pipelines if SageMaker Pipelines sound new to you.
Familiarity with Managing your machine learning lifecycle with MLflow and Amazon SageMaker and its example lab.
Access to an Amazon SageMaker Studio environment and be familiar with the Studio user interface.
Docker to build and push the MLFlow inference container image to ECR.
This GitHub repository cloned into your studio environment
Step 1: Deploying MLflow on AWS and launching the MLOps project in SageMaker
Deploying MLflow on AWS Fargate
First, we need to set up a central MLflow tracking server so we can use it in our MLOps project.

If you don’t have one, you can follow instructions and blog explanations to deploy the open source version of MLflow on AWS Fargate.


Image by author: Hosting MLflow on AWS Fargate, with Amazon S3 as artifact store, and Amazon RDS for MySQL as backend store.

Image by author: Once deployed, make sure you keep the load balancer URI somewhere. We will use it in our MLOps project so the pipelines can talk to MLflow.
Launching your MLOps project
Now, we need to launch a SageMaker project based on the MLOps template for model building, training, and deployment.

You can follow Julien Simon’s walk through video to do this:


The project template will create 2 CodeCommit repos for modelBuild and modelDeploy, 2 CodePipeline pipelines for CI and CD, CodeBuild projects for packaging and testing artifacts, and other resources to run the project.


Image by author: You can clone the repos in your environment.
Allowing the project to access the MLflow artifact store
We use Amazon S3 as artifact store for MLflow and you will need to update the MLOps project role, so it can access the MLflow S3 bucket.

The role is called AmazonSageMakerServiceCatalogProductsUseRole and you can update its permissions like I did below:


Image by author: I use managed policies for this example. You may tighten permissions in your environment.
Step 2: Updating the modelBuild pipeline to log models into MLflow
After cloning the modelBuild repository into your environment you can update the code with the one from the model_build folder.



Images by author: How your modelBuild repo should look like before (left) and after updating it (right)
You can find the example ML pipeline in pipeline.py. It has 2 simple steps:

PrepareData gets the dataset from sklearn and splits it into train/test sets
TrainEvaluateRegister trains a Random Forest model, logs parameters, metrics, and the model into MLflow.
At line 22 of pipeline.py, make sure you add your MLflow load balancer URI to the pipeline parameter. It will be passed to TrainEvaluateRegister so it knows where to point to find MLflow.

You can now push the updated code to the main branch of the repo.


Image by author: Your pipeline will be updated and take a few minutes to execute.
From now on, the pipeline will register a new model version in MLflow at each execution.


Image by author
To further automate, you can schedule the pipeline with Amazon EventBridge, or use other type of triggers with the start_pipeline_execution method.

Step 3: Deploying the MLflow models into production with the modelDeploy pipeline
We can now bring new model versions to the MLflow model registry, and will use the modelDeploy side of the MLOps project to deploy them into production.

Pushing the inference container image to ECR
Alongside the ML model, we need a container image to handle the inference in our SageMaker Endpoint. Let’s push the one provided by MLflow into ECR. Make sure this is done in the same AWS region as your MLOps project is in.

In my case, I push it from my laptop using the following commands:

pip install -q mlflow==1.23.1
mlflow sagemaker build-and-push-container
Updating the modelDeploy repo
Next, you can update the modelDeploy repo with the code from this folder.



Images by author: How your modelDeploy repo should look like before (left) and after updating it (right)
In buildspec.yml, you can define the model version to deploy into production. You will also need to input your MLflow load balancer URI, and Inference container URI.


Image by author
I updated build.py to get the chosen model version binary from MLflow, and upload its model.tar.gz to S3.

This is done by mlflow_handler.py, which also transitions model stages in MLflow, as models go through the modelDeploy Pipeline.

Triggering the deployment
You can now push the code to the main branch of the repo, which will trigger the modelDeploy pipeline in CodePipeline. Once testing is successful in staging, you can navigate to the CodePipeline console and manually approve the endpoint to go to production.



Images by author: Model stages will be transitioned in MLflow, as it progresses through the pipeline
When deploying a new version, the pipeline will archive the previous one.


Image by author
And you can see your SageMaker Endpoints ready to generate predictions.


Image by author
Conclusion
Amazon SageMaker Pipelines brings MLOps tooling into one umbrella to reduce the effort of running end-to-end MLOps projects.

In this post, we used a SageMaker MLOps project and the MLflow model registry to automate an end-to-end ML lifecycle.

To go further, you can also learn how to deploy a Serverless Inference Service Using Amazon SageMaker Pipelines.


Example 3
From 429 to 200: How API Gateways Solve Rate Limiting
# Scaling LLM Applications with LiteLLM Proxy on AWS: A Multi-Account Strategy for Handling Rate Limits

Have you ever hit that dreaded "429 Too Many Requests" error when working with large language models (LLMs)? If so, you're not alone. As AI applications become more prevalent, managing rate limits and scaling LLM deployments has become a significant challenge for many organizations. But what if I told you there's a way to overcome these limitations and build a robust, scalable LLM infrastructure? Enter LiteLLM Proxy on AWS Fargate.

In this post, I'll walk you through a powerful architecture that leverages LiteLLM Proxy to distribute load across multiple AWS accounts, effectively solving the rate limit puzzle. We'll explore how to set up this system, connect it to AWS Bedrock, and implement a smart load-balancing strategy to keep your AI applications running smoothly, even under heavy load.

## The Power of LiteLLM Proxy

Before we dive into the nitty-gritty, let's talk about what makes LiteLLM Proxy so special. Think of it as the Swiss Army knife for LLM APIs. It's an open-source tool that acts as a unified interface for accessing over 100 different language models. In essence, it's the Rosetta Stone for LLM communication.

LiteLLM offers two main modes of operation:

1. As an SDK for direct code integration
2. As a proxy server that presents a single OpenAI-compatible API

For enterprise deployments, the proxy mode is where the magic happens. It provides:

- Centralized management of API calls to various LLM providers
- Flexibility to switch between models without code changes
- Advanced routing capabilities for handling quotas and load balancing
- Comprehensive logging and monitoring for performance tracking and cost management

The best part? LiteLLM Proxy presents an OpenAI-compatible endpoint, meaning any application built for OpenAI's API can work with LiteLLM with minimal changes. Talk about a game-changer for integration!

## The Rate Limiting Challenge

Now, let's address the elephant in the room: rate limits. When working with LLM providers, you'll inevitably run into these roadblocks, which manifest as those pesky HTTP 429 "Too Many Requests" errors. These limits can come in various flavors:

- Token rate limits
- Request rate limits
- Concurrent request limits

For high-throughput applications or those serving numerous users, these limits can quickly become a bottleneck. This is particularly true for AWS Bedrock, which applies quotas at the account level.

## Our Solution: LiteLLM on AWS Fargate

To tackle this challenge head-on, we'll deploy LiteLLM Proxy on AWS Fargate and connect it to multiple AWS Bedrock accounts. This architecture includes:

- AWS Fargate for hosting and scaling LiteLLM Proxy containers
- Cross-account IAM roles to optimize AWS Bedrock quota usage
- Amazon S3 for storing LiteLLM configuration files
- CloudWatch for monitoring and logging
- AWS Application Load Balancer for distributing incoming traffic

This setup enables intelligent routing of requests across multiple AWS accounts, effectively multiplying your available quotas. Let's break down the implementation step by step.

## Setting Up LiteLLM Proxy on AWS Fargate

### Step 1: Create an ECR Repository

First things first, let's create an Elastic Container Registry (ECR) repository to store our LiteLLM Proxy container image:

```bash
aws ecr create-repository --repository-name litellm-proxy
```

### Step 2: Build and Push the LiteLLM Container

Now, let's create a Dockerfile for our LiteLLM Proxy:

```dockerfile
FROM python:3.9-slim

WORKDIR /app

RUN pip install --no-cache-dir litellm

COPY config.yaml /app/config.yaml

EXPOSE 8000

CMD ["litellm", "--proxy", "--config", "/app/config.yaml"]
```

Build and push the image:

```bash
aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
docker build -t litellm-proxy .
docker tag litellm-proxy:latest $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/litellm-proxy:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/litellm-proxy:latest
```

### Step 3: Create an S3 Bucket for Configuration

Store your LiteLLM configuration in an S3 bucket for easy updates:

```bash
aws s3 mb s3://litellm-config-$AWS_ACCOUNT_ID
```

### Step 4: Create the Fargate Cluster and Task Definition

Use AWS CLI or CloudFormation to create a Fargate cluster and task definition. Here's a simplified CloudFormation template snippet:

```yaml
Resources:
  LiteLLMCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: litellm-cluster

  LiteLLMTaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: litellm-proxy
      Cpu: '1024'
      Memory: '2048'
      NetworkMode: awsvpc
      RequiresCompatibilities:
        - FARGATE
      ExecutionRoleArn: !GetAtt LiteLLMExecutionRole.Arn
      TaskRoleArn: !GetAtt LiteLLMTaskRole.Arn
      ContainerDefinitions:
        - Name: init-container
          Image: amazon/aws-cli
          Essential: false
          Command:
            - "s3"
            - "cp"
            - "s3://litellm-config-${AWS::AccountId}/config.yaml"
            - "/config/config.yaml"
          MountPoints:
            - SourceVolume: config-volume
              ContainerPath: /config
        - Name: litellm-proxy
          Image: !Sub ${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com/litellm-proxy:latest
          Essential: true
          PortMappings:
            - ContainerPort: 8000
              HostPort: 8000
          DependsOn:
            - ContainerName: init-container
              Condition: SUCCESS
          MountPoints:
            - SourceVolume: config-volume
              ContainerPath: /app/config
          LogConfiguration:
            LogDriver: awslogs
            Options:
              awslogs-group: !Ref LiteLLMLogGroup
              awslogs-region: !Ref AWS::Region
              awslogs-stream-prefix: litellm
      Volumes:
        - Name: config-volume
          EmptyVolume: {}
```

### Step 5: Create a Service to Run the Tasks

Deploy the LiteLLM Proxy as a service for high availability:

```yaml
  LiteLLMService:
    Type: AWS::ECS::Service
    Properties:
      ServiceName: litellm-proxy-service
      Cluster: !Ref LiteLLMCluster
      TaskDefinition: !Ref LiteLLMTaskDefinition
      DesiredCount: 2
      LaunchType: FARGATE
      NetworkConfiguration:
        AwsvpcConfiguration:
          AssignPublicIp: ENABLED
          Subnets:
            - subnet-xxxxxxxx
            - subnet-yyyyyyyy
          SecurityGroups:
            - !Ref LiteLLMSecurityGroup
      LoadBalancers:
        - TargetGroupArn: !Ref LiteLLMTargetGroup
          ContainerName: litellm-proxy
          ContainerPort: 8000
```

## Connecting to AWS Bedrock

Now comes the exciting part - connecting LiteLLM to AWS Bedrock. The key here is to use IAM roles for secure access without handling credentials in your application.

### Creating the LiteLLM Configuration

Create a `config.yaml` file that defines your model deployments:

```yaml
model_list:
  - model_name: anthropic.claude-v2
    litellm_params:
      model: bedrock/anthropic.claude-v2
      aws_region: us-east-1
      aws_role_arn: arn:aws:iam::111111111111:role/LiteLLMBedrockAccessRole
      aws_session_name: LitellmBedrockSession

  - model_name: anthropic.claude-v2-account2
    litellm_params:
      model: bedrock/anthropic.claude-v2
      aws_region: us-east-1
      aws_role_arn: arn:aws:iam::222222222222:role/LiteLLMBedrockAccessRole
      aws_session_name: LitellmBedrockSession

  - model_name: anthropic.claude-instant-v1
    litellm_params:
      model: bedrock/anthropic.claude-instant-v1
      aws_region: us-west-2
      aws_role_arn: arn:aws:iam::111111111111:role/LiteLLMBedrockAccessRole
      aws_session_name: LitellmBedrockSession

router_settings:
  routing_strategy: least-busy
  fallbacks: [
    {
      "anthropic.claude-v2": ["anthropic.claude-v2-account2", "anthropic.claude-instant-v1"]
    }
  ]

environment_variables:
  AWS_WEB_IDENTITY_TOKEN_FILE: /var/run/secrets/eks.amazonaws.com/serviceaccount/token

litellm_settings:
  success_callback: ["log_to_cloudwatch"]
  failure_callback: ["log_to_cloudwatch"]
```

Upload this configuration to your S3 bucket:

```bash
aws s3 cp config.yaml s3://litellm-config-$AWS_ACCOUNT_ID/config.yaml
```

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

## Spreading Load Across Multiple AWS Accounts

Now for the pièce de résistance - using LiteLLM's routing capabilities to distribute load across multiple AWS accounts, effectively multiplying your available quotas.

### Load Balancing Strategy

LiteLLM Proxy offers several routing strategies, but for our multi-account strategy, the "Least Busy" approach works exceptionally well. It monitors the number of active requests per model and routes new requests to the model with the fewest active requests, ensuring optimal distribution across accounts.

### Fallback Mechanisms

To handle rate limits gracefully, configure fallbacks in your `config.yaml`. When a model returns a 429 error, LiteLLM will automatically retry the request with the next model in the fallback chain:

```yaml
router_settings:
  routing_strategy: least-busy
  fallbacks: [
    {
      "anthropic.claude-v2": ["anthropic.claude-v2-account2", "anthropic.claude-instant-v1"]
    }
  ]
```

This configuration will first try `anthropic.claude-v2` in the primary account, then fall back to the same model in the second account if rate limited, and finally try `anthropic.claude-instant-v1` as a last resort.

## Putting It All Together: A Multi-Account Setup

Imagine distributing load across three AWS accounts, each with its own Bedrock quotas. Your architecture would involve:

- A central AWS account running LiteLLM Proxy on Fargate
- Three AWS accounts with Bedrock enabled
- Cross-account IAM roles for secure access
- An Application Load Balancer exposing a single endpoint to clients

## Making Requests to the Proxy

Once deployed, you can call the LiteLLM Proxy using standard OpenAI-compatible API calls:

Using curl:

```bash
curl -X POST "https://your-alb-endpoint.us-east-1.elb.amazonaws.com/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your_api_key" \
  -d '{
    "model": "anthropic.claude-v2",
    "messages": [
      {"role": "user", "content": "Explain quantum computing in simple terms"}
    ]
  }'
```

Using Python:

```python
from openai import OpenAI

client = OpenAI(
    api_key="your_api_key",
    base_url="https://your-alb-endpoint.us-east-1.elb.amazonaws.com"
)

response = client.chat.completions.create(
    model="anthropic.claude-v2",
    messages=[
        {"role": "user", "content": "Explain quantum computing in simple terms"}
    ]
)

print(response.choices[0].message.content)
```

Behind the scenes, LiteLLM Proxy will intelligently route this request to one of your configured model deployments across multiple accounts, using the least busy strategy to avoid rate limits.

## Monitoring and Logging

To keep your finger on the pulse of your LLM infrastructure, set up comprehensive monitoring:

1. Configure CloudWatch Logs for the LiteLLM container
2. Create CloudWatch Dashboards to visualize:
   - Request rates per model
   - Error rates, especially 429 errors
   - Average response times
   - Resource utilization (CPU, memory)
3. Set up CloudWatch Alarms for:
   - Sustained high error rates
   - Approaching quota limits
   - Service unavailability

LiteLLM also supports various alerting integrations (Slack, Discord, Microsoft Teams), which can be configured for real-time notifications about performance issues or quota consumption.

## Conclusion

Implementing LiteLLM Proxy on AWS Fargate with a multi-account strategy provides a robust solution for organizations facing LLM rate limiting challenges. This architecture delivers several key benefits:

- Increased throughput by leveraging quotas across multiple AWS accounts
- Enhanced reliability through intelligent routing and fallbacks
- Simplified API management with a standardized OpenAI-compatible interface
- Cost optimization by distributing load efficiently
- Improved observability with comprehensive logging and monitoring

As LLMs continue to become critical components of modern applications, managing their scalability becomes paramount. LiteLLM Proxy provides the flexibility and robustness needed to handle enterprise-scale deployments while mitigating the limitations imposed by individual providers.

By following the implementation steps outlined in this post, you can build a solution that scales with your organization's needs and ensures consistent, reliable access to LLM capabilities, no matter how much your demand grows.

The next frontier in this evolution will be implementing more sophisticated caching mechanisms and exploring multi-region deployments for even greater resilience and performance optimization. Are you ready to take your LLM infrastructure to the next level?

Example 4
Managing your machine learning lifecycle with MLflow and Amazon SageMaker
by Sofian Hamiti and Shreyas Subramanian on 28 JAN 2021 in Amazon SageMaker, Artificial Intelligence Permalink  Comments  Share
June 2024: The contents of this post are out of date. We recommend you refer to Announcing the general availability of fully managed MLflow on Amazon SageMaker for the latest.

With the rapid adoption of machine learning (ML) and MLOps, enterprises want to increase the velocity of ML projects from experimentation to production.

During the initial phase of an ML project, data scientists collaborate and share experiment results in order to find a solution to a business need. During the operational phase, you also need to manage the different model versions going to production and your lifecycle. In this post, we’ll show how the open-source platform MLflow helps address these issues. For those interested in a fully managed solution, Amazon Web Services recently announced Amazon SageMaker Pipelines at re:Invent 2020, the first purpose-built, easy-to-use continuous integration and continuous delivery (CI/CD) service for machine learning (ML). You can learn more about SageMaker Pipelines in this post.

MLflow is an open-source platform to manage the ML lifecycle, including experimentation, reproducibility, deployment, and a central model registry. It includes the following components:

Tracking – Record and query experiments: code, data, configuration, and results
Projects – Package data science code in a format to reproduce runs on any platform
Models – Deploy ML models in diverse serving environments
Registry – Store, annotate, discover, and manage models in a central repository
The following diagram illustrates our architecture.



In the following sections, we show how to deploy MLflow on AWS Fargate and use it during your ML project with Amazon SageMaker. We use SageMaker to develop, train, tune, and deploy a Scikit-learn based ML model (random forest) using the Boston House Prices dataset. During our ML workflow, we track experiment runs and our models with MLflow.

SageMaker is a fully managed service that provides developers and data scientists the ability to build, train, and deploy ML models quickly. SageMaker removes the heavy lifting from each step of the ML process to make it easier to develop high-quality models.

Walkthrough overview
This post demonstrates how to do the following:

Host a serverless MLflow server on Fargate
Set Amazon Simple Storage Service (Amazon S3) and Amazon Relational Database Service (Amazon RDS) as artifact and backend stores, respectively
Track experiments running on SageMaker with MLflow
Register models trained in SageMaker in the MLflow Model Registry
Deploy an MLflow model into a SageMaker endpoint
The detailed step-by-step code walkthrough is available in the GitHub repo.

Architecture overview
You can set up a central MLflow tracking server during your ML project. You use this remote MLflow server to manage experiments and models collaboratively. In this section, we show you how you can Dockerize your MLflow tracking server and host it on Fargate.

An MLflow tracking server also has two components for storage: a backend store and an artifact store.

We use an S3 bucket as our artifact store and an Amazon RDS for MySQL instance as our backend store.

The following diagram illustrates this architecture.



Running an MLflow tracking server on a Docker container
You can install MLflow using pip install mlflow and start your tracking server with the mlflow server command.

By default, the server runs on port 5000, so we expose it in our container. Use 0.0.0.0 to bind to all addresses if you want to access the tracking server from other machines. We install boto3 and pymysql dependencies for the MLflow server to communicate with the S3 bucket and the RDS for MySQL database. See the following code:

FROM python:3.8.0

RUN pip install \
    mlflow \
    pymysql \
    boto3 & \
    mkdir /mlflow/

EXPOSE 5000

## Environment variables made available through the Fargate task.
## Do not enter values
CMD mlflow server \
    --host 0.0.0.0 \
    --port 5000 \
    --default-artifact-root ${BUCKET} \
    --backend-store-uri mysql+pymysql://${USERNAME}:${PASSWORD}@${HOST}:${PORT}/${DATABASE}
Hosting an MLflow tracking server with Fargate
In this section, we show how you can run your MLflow tracking server on a Docker container that is hosted on Fargate.

Fargate is an easy way to deploy your containers on AWS. It allows you to use containers as a fundamental compute primitive without having to manage the underlying instances. All you need is to specify an image to deploy and the amount of CPU and memory it requires. Fargate handles updating and securing the underlying Linux OS, Docker daemon, and Amazon Elastic Container Service (Amazon ECS) agent, as well as all the infrastructure capacity management and scaling.

For more information about running an application on Fargate, see Building, deploying, and operating containerized applications with AWS Fargate.

The MLflow container first needs to be built and pushed to an Amazon Elastic Container Registry (Amazon ECR) repository. The container image URI is used at registration of our Amazon ECS task definition. The ECS task has an AWS Identity and Access Management (IAM) role attached to it, allowing it to interact with AWS services such as Amazon S3.

The following screenshot shows our task configuration.



The Fargate service is set up with autoscaling and a network load balancer so it can adjust to the required compute load with minimal maintenance effort on our side.

When running our ML project, we set mlflow.set_tracking_uri(<load balancer uri>) to interact with the MLflow server via the load balancer.

Using Amazon S3 as the artifact store and Amazon RDS for MySQL as backend store
The artifact store is suitable for large data (such as an S3 bucket or shared NFS file system) and is where clients log their artifact output (for example, models). MLflow natively supports Amazon S3 as artifact store, and you can use --default-artifact-root ${BUCKET} to refer to the S3 bucket of your choice.

The backend store is where MLflow Tracking Server stores experiments and runs metadata, as well as parameters, metrics, and tags for runs. MLflow supports two types of backend stores: file store and database-backed store. It’s better to use an external database-backed store to persist the metadata.

As of this writing, you can use databases such as MySQL, SQLite, and PostgreSQL as a backend store with MLflow. For more information, see Backend Stores.

Amazon Aurora is a MySQL and PostgreSQL-compatible relational database and can also be used for this.

For this example, we set up an RDS for MySQL instance. Amazon RDS makes it easy to set up, operate, and scale MySQL deployments in the cloud. With Amazon RDS, you can deploy scalable MySQL servers in minutes with cost-efficient and resizable hardware capacity.

You can use --backend-store-uri mysql+pymysql://${USERNAME}:${PASSWORD}@${HOST}:${PORT}/${DATABASE} to refer MLflow to the MySQL database of your choice.

Launching the example MLflow stack
To launch your MLflow stack, follow these steps:

Launch the AWS CloudFormation stack provided in the GitHub repo
Choose Next.
Leave all options as default until you reach the final screen.
Select I acknowledge that AWS CloudFormation might create IAM resources.
Choose Create.
The stack takes a few minutes to launch the MLflow server on Fargate, with an S3 bucket and a MySQL database on RDS. The load balancer URI is available on the Outputs tab of the stack.



You can then use the load balancer URI to access the MLflow UI.



In this illustrative example stack, our load balancer is launched on a public subnet and is internet facing.

For security purposes, you may want to provision an internal load balancer in your VPC private subnets where there is no direct connectivity from the outside world. For more information, see Access Private applications on AWS Fargate using Amazon API Gateway PrivateLink.

Tracking SageMaker runs with MLflow
You now have a remote MLflow tracking server running accessible through a REST API via the load balancer URI.

You can use the MLflow Tracking API to log parameters, metrics, and models when running your ML project with SageMaker. For this you need to install the MLflow library when running your code on SageMaker and set the remote tracking URI to be your load balancer address.

The following Python API command allows you to point your code running on SageMaker to your MLflow remote server:

import mlflow
mlflow.set_tracking_uri('<YOUR LOAD BALANCER URI>')
Connect to your notebook instance and set the remote tracking URI. The following diagram shows the updated architecture.



Managing your ML lifecycle with SageMaker and MLflow
You can follow this example lab by running the notebooks in the GitHub repo.

This section describes how to develop, train, tune, and deploy a random forest model using Scikit-learn with the SageMaker Python SDK. We use the Boston Housing dataset, present in Scikit-learn, and log our ML runs in MLflow.

You can find the original lab in the SageMaker Examples GitHub repo for more details on using custom Scikit-learn scripts with SageMaker.

Creating an experiment and tracking ML runs
In this project, we create an MLflow experiment named boston-house and launch training jobs for our model in SageMaker. For each training job run in SageMaker, our Scikit-learn script records a new run in MLflow to keep track of input parameters, metrics, and the generated random forest model.

The following example API calls can help you start and manage MLflow runs:

start_run() – Starts a new MLflow run, setting it as the active run under which metrics and parameters are logged
log_params() – Logs a parameter under the current run
log_metric() – Logs a metric under the current run
sklearn.log_model() – Logs a Scikit-learn model as an MLflow artifact for the current run
For a complete list of commands, see MLflow Tracking.

The following code demonstrates how you can use those API calls in your train.py script:

# set remote mlflow server
mlflow.set_tracking_uri(args.tracking_uri)
mlflow.set_experiment(args.experiment_name)

with mlflow.start_run():
    params = {
        "n-estimators": args.n_estimators,
        "min-samples-leaf": args.min_samples_leaf,
        "features": args.features
    }
    mlflow.log_params(params)
    
    # TRAIN
    logging.info('training model')
    model = RandomForestRegressor(
        n_estimators=args.n_estimators,
        min_samples_leaf=args.min_samples_leaf,
        n_jobs=-1
    )

    model.fit(X_train, y_train)

    # ABS ERROR AND LOG COUPLE PERF METRICS
    logging.info('evaluating model')
    abs_err = np.abs(model.predict(X_test) - y_test)

    for q in [10, 50, 90]:
        logging.info(f'AE-at-{q}th-percentile: {np.percentile(a=abs_err, q=q)}')
        mlflow.log_metric(f'AE-at-{str(q)}th-percentile', np.percentile(a=abs_err, q=q))

    # SAVE MODEL
    logging.info('saving model in MLflow')
    mlflow.sklearn.log_model(model, "model")
Your train.py script needs to know which MLflow tracking_uri and experiment_name to use to log the runs. You can pass those values to your script using the hyperparameters of the SageMaker training jobs. See the following code:

# uri of your remote mlflow server
tracking_uri = '<YOUR LOAD BALANCER URI>' 
experiment_name = 'boston-house'

hyperparameters = {
    'tracking_uri': tracking_uri,
    'experiment_name': experiment_name,
    'n-estimators': 100,
    'min-samples-leaf': 3,
    'features': 'CRIM ZN INDUS CHAS NOX RM AGE DIS RAD TAX PTRATIO B LSTAT',
    'target': 'target'
}

estimator = SKLearn(
    entry_point='train.py',
    source_dir='source_dir',
    role=role,
    metric_definitions=metric_definitions,
    hyperparameters=hyperparameters,
    train_instance_count=1,
    train_instance_type='local',
    framework_version='0.23-1',
    base_job_name='mlflow-rf',
)
Performing automatic model tuning with SageMaker and tracking with MLflow
SageMaker automatic model tuning, also known as Hyperparameter Optimization (HPO), finds the best version of a model by running many training jobs on your dataset using the algorithm and ranges of hyperparameters that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by a metric that you choose.

In the 2_track_experiments_hpo.ipynb example notebook, we show how you can launch a SageMaker tuning job and track its training jobs with MLflow. It uses the same train.py script and data used in single training jobs, so you can accelerate your hyperparameter search for your MLflow model with minimal effort.

When the SageMaker jobs are complete, you can navigate to the MLflow UI and compare results of different runs (see the following screenshot).



This can be useful to promote collaboration within your development team.

Managing models trained with SageMaker using the MLflow Model Registry
The MLflow Model Registry component allows you and your team to collaboratively manage the lifecycle of a model. You can add, modify, update, transition, or delete models created during the SageMaker training jobs in the Model Registry through the UI or the API.

In your project, you can select a run with the best model performance and register it into the MLflow Model Registry. The following screenshot shows example registry details.



After a model is registered, you can navigate to the Registered Models page and view its properties.



Deploying your model in SageMaker using MLflow
This sections shows how to use the mlflow.sagemaker module provided by MLflow to deploy a model into a SageMaker-managed endpoint. As of this writing, MLflow only supports deployments to SageMaker endpoints, but you can use the model binaries from the Amazon S3 artifact store and adapt them to your deployment scenarios.

Next, you need to build a Docker container with inference code and push it to Amazon ECR.

You can build your own image or use the mlflow sagemaker build-and-push-container command to have MLflow create one for you. This builds an image locally and pushes it to an Amazon ECR repository called mlflow-pyfunc.



The following example code shows how to use mlflow.sagemaker.deploy to deploy your model into a SageMaker endpoint:

# URL of the ECR-hosted Docker image the model should be deployed into
image_uri = '<YOUR mlflow-pyfunc ECR IMAGE URI>'
endpoint_name = 'boston-housing'
# The location, in URI format, of the MLflow model to deploy to SageMaker.
model_uri = '<YOUR MLFLOW MODEL LOCATION>'

mlflow.sagemaker.deploy(
    mode='create',
    app_name=endpoint_name,
    model_uri=model_uri,
    image_url=image_uri,
    execution_role_arn=role,
    instance_type='ml.m5.xlarge',
    instance_count=1,
    region_name=region
)
The command launches a SageMaker endpoint into your account, and you can use the following code to generate predictions in real time:


Example 5
# Scaling LLM Applications with LiteLLM on AWS Fargate: A Multi-Account Strategy for Handling Rate Limits


Have you ever hit that dreaded "429 Too Many Requests" error when working with large language models (LLMs)? As AI applications become more prevalent in production environments, managing rate limits and scaling LLM deployments has become a significant challenge for many organizations. In this post, I'll show you how to overcome these limitations by building a robust, scalable LLM infrastructure using LiteLLM Proxy on AWS Fargate.

We'll explore a powerful architecture that leverages LiteLLM Proxy to distribute load across multiple AWS accounts, effectively solving the rate limit puzzle. I'll walk you through setting up this system, connecting it to AWS Bedrock, and implementing a smart load-balancing strategy to keep your AI applications running smoothly, even under heavy load.

## What is LiteLLM?

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

## The Rate Limiting Challenge

When working with LLM providers, you'll inevitably run into rate limits, which manifest as HTTP 429 "Too Many Requests" errors. These limits can come in various flavors:

- **Token rate limits** (TPM - tokens per minute)
- **Request rate limits** (RPM - requests per minute)
- **Concurrent request limits**

For high-throughput applications or those serving numerous users, these limits can quickly become a bottleneck. This is particularly true for AWS Bedrock, which applies quotas at the account level rather than the model level.

Consider this scenario: Your application needs to handle 100 requests per minute, but your AWS Bedrock account has a quota of only 50 RPM for Claude models. Without a solution to manage these limits, your application will experience frequent failures, leading to poor user experience and potential business impact.

## Solution Architecture: LiteLLM on AWS Fargate

To tackle this challenge head-on, we'll deploy LiteLLM Proxy on AWS Fargate and connect it to multiple AWS Bedrock accounts. This architecture includes:

- **AWS Fargate** for hosting and scaling LiteLLM Proxy containers
- **Cross-account IAM roles** to optimize AWS Bedrock quota usage
- **Amazon S3** for storing LiteLLM configuration files
- **CloudWatch** for monitoring and logging
- **AWS Application Load Balancer** for distributing incoming traffic

![LiteLLM AWS Architecture](https://raw.githubusercontent.com/sofianhamiti/litellm-aws-fargate/main/docs/images/litellm-aws-architecture.png)

This setup enables intelligent routing of requests across multiple AWS accounts, effectively multiplying your available quotas. Let's break down the implementation step by step.

## Deploying LiteLLM on AWS Fargate

### Security First: Private Subnet Deployment

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

### Deployment Using Terraform

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

## Connecting LiteLLM to AWS Bedrock

Now comes the exciting part - connecting LiteLLM to AWS Bedrock across multiple accounts. The key here is to use IAM roles for secure access without handling credentials in your application.

### LiteLLM Configuration for AWS Bedrock

The LiteLLM configuration file (`litellm_config.yaml`) defines your model deployments and routing strategy. Here's an example configuration that connects to AWS Bedrock across multiple accounts:

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

## Spreading Load Across Multiple AWS Accounts

Now for the pièce de résistance - using LiteLLM's routing capabilities to distribute load across multiple AWS accounts, effectively multiplying your available quotas.

### Load Balancing Strategy

LiteLLM Proxy offers several routing strategies, but for our multi-account strategy, the "Least Busy" approach works exceptionally well. It monitors the number of active requests per model and routes new requests to the model with the fewest active requests, ensuring optimal distribution across accounts.

![Load Balancing Diagram](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*JKH8FVL5WGZphnT7zzuXzg.png)

### Fallback Mechanisms

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

## Making Requests to the LiteLLM Proxy

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

## Monitoring and Optimizing Performance

To keep your finger on the pulse of your LLM infrastructure, set up comprehensive monitoring:

1. Configure CloudWatch Logs for the LiteLLM container
2. Create CloudWatch Dashboards to visualize:
   - Request rates per model
   - Error rates, especially 429 errors
   - Average response times
   - Resource utilization (CPU, memory)
3. Set up CloudWatch Alarms for:
   - Sustained high error rates
   - Approaching quota limits
   - Service unavailability

Here's an example CloudWatch dashboard that tracks key metrics:

![CloudWatch Dashboard](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*YqH8sMJfaYmkJLLZJQMr3g.png)

## Cost Optimization

While this architecture provides significant benefits in terms of scalability and reliability, it's important to optimize costs. Here are some strategies:

1. **Right-size Fargate Tasks**: Monitor CPU and memory utilization and adjust resources based on actual usage.

2. **Optimize Aurora PostgreSQL Costs**: Set appropriate min/max capacity based on actual usage.

3. **Reduce Client VPN Costs**: Disable the Client VPN endpoint when not in use.

4. **Optimize NAT Gateway Usage**: Use a single NAT Gateway instead of one per AZ for non-production environments.

5. **Implement Autoscaling with Scheduled Actions**: Use scheduled scaling to reduce capacity during off-hours.

```hcl
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

6. **Use Spot Capacity for Non-Production Workloads**: Fargate Spot provides up to 70% cost savings compared to on-demand pricing.

## Real-World Example: Handling High-Traffic AI Applications

Let's consider a real-world scenario where this architecture proves invaluable. Imagine you're building an AI-powered customer service application that needs to handle thousands of concurrent user queries. Each query requires a call to Claude on AWS Bedrock, but you're limited by the default quota of 5 requests per second per account.

With our multi-account LiteLLM setup, you can:

1. Distribute load across 5 AWS accounts, effectively increasing your quota to 25 requests per second
2. Implement intelligent routing to ensure optimal utilization of each account's quota
3. Set up automatic fallbacks to handle rate limit errors gracefully
4. Monitor usage patterns and adjust your infrastructure accordingly

The result? A robust, scalable AI application that can handle high traffic without disruption, providing a seamless experience for your users.

## Conclusion

Implementing LiteLLM Proxy on AWS Fargate with a multi-account strategy provides a robust solution for organizations facing LLM rate limiting challenges. This architecture delivers several key benefits:

- **Increased throughput** by leveraging quotas across multiple AWS accounts
- **Enhanced reliability** through intelligent routing and fallbacks
- **Simplified API management** with a standardized OpenAI-compatible interface
- **Cost optimization** by distributing load efficiently
- **Improved observability** with comprehensive logging and monitoring

As LLMs continue to become critical components of modern applications, managing their scalability becomes paramount. LiteLLM Proxy provides the flexibility and robustness needed to handle enterprise-scale deployments while mitigating the limitations imposed by individual providers.

By following the implementation steps outlined in this post, you can build a solution that scales with your organization's needs and ensures consistent, reliable access to LLM capabilities, no matter how much your demand grows.

The next frontier in this evolution will be implementing more sophisticated caching mechanisms and exploring multi-region deployments for even greater resilience and performance optimization. Are you ready to take your LLM infrastructure to the next level?

---

*If you found this article helpful, follow me on [Medium](https://medium.com/@sofian-hamiti) for more content on AWS, machine learning, and MLOps.*


Example 6
# Scaling LLM Applications Without the Headache: How We Beat Rate Limits with LiteLLM and AWS  

Picture this: It's 3 AM. Your AI-powered customer service bot is drowning in requests. Panic sets in as you stare at the logs—**429 errors everywhere**. Sound familiar? You're not alone. But what if I told you there's a way to turn this nightmare into a smooth sailing operation? Let me show you how we did it using LiteLLM and some AWS wizardry.  

## Why LiteLLM Became Our Secret Weapon  

Let's cut to the chase—**every LLM project hits rate limits eventually**. We learned this the hard way when our Claude-powered analytics dashboard started coughing up more 429s than actual insights. That's when we discovered LiteLLM, the "universal remote" of language models.  

Here's why it rocked our world:  

1. **One API to rule them all** (okay, 100+ models)  
2. **Real-time traffic cop** for managing rate limits  
3. **Automatic failover** when models get grumpy  
4. **Cost tracking** that actually makes sense  

But here's the kicker—it speaks **OpenAI-flavored REST**, meaning our existing code just worked. No rewrite headaches.  

## Our "Aha" Architecture Moment  

After burning midnight oil (and several AWS support tickets), we landed on this beauty:  

```
[Your App] → [ALB] → [LiteLLM on Fargate] → [Cross-Account Bedrock Roles]  
                ↳ CloudWatch Dashboard (Our anxiety meter)  
```

The magic sauce? **Spreading love (and requests)** across multiple AWS accounts. Here's why it's genius:  

- Each AWS account = Fresh set of rate limits  
- LiteLLM becomes the ultimate traffic director  
- Zero code changes for existing clients  

## From Zero to Hero: Deployment Made Painless  

### Step 1: Containerize Like a Pro  

We ditched the S3 config dance—**bake it right into the image**:  

```dockerfile  
FROM python:3.9-slim  
WORKDIR /app  
RUN pip install litellm  
COPY config.yaml models.json ./  
CMD ["litellm", "--config", "./config.yaml"]  
```

**Pro Tip:** Use multi-stage builds to keep images lean. Your future self will thank you during deployments.  

### Step 2: Terraform Magic  

Our infrastructure-as-code approach:  

```hcl  
module "litellm_cluster" {  
  source = "terraform-aws-modules/ecs/aws"  
  name   = "llm-traffic-cop"  
}  

resource "aws_ecs_task_definition" "litellm" {  
  container_definitions = jsonencode([{  
    name  = "litellm-proxy"  
    image = "${aws_ecr_repository.litellm.repository_url}:latest"  
    portMappings = [{ containerPort = 8000 }]  
  }])  
}  
```

**Fun Fact:** This setup auto-scales based on request volume. We slept better knowing it could handle traffic spikes.  

### Step 3: Cross-Account Voodoo  

The IAM magic that makes it tick:  

```json  
{  
  "Version": "2012-10-17",  
  "Statement": [  
    {  
      "Effect": "Allow",  
      "Action": "sts:AssumeRole",  
      "Principal": {  
        "AWS": "arn:aws:iam::MAIN_ACCOUNT:role/LiteLLM-Proxy"  
      }  
    }  
  ]  
}  
```

**Translation:** "Hey AWS, let our proxy wear multiple hats across accounts."  

## Real-World Smackdown: How We Crushed 429s  

Let me walk you through our "Oh $#!%" moment:  

**Scenario:**  
- 500 RPM needed for peak traffic  
- Single AWS account limit: 200 RPM  

**Old Way:**  
```  
[Your App] → [Account 1] → 💥 429s galore 💥  
```

**New Way with LiteLLM:**  
```  
[Your App] → [Traffic Cop]  
               ├→ [Account 1] (200 RPM)  
               ├→ [Account 2] (200 RPM)  
               └→ [Account 3] (200 RPM)  
```

**The Result?** Smooth sailing at 600 RPM capacity. Sales team stopped yelling. CEO smiled. All was right with the world.  

## Pro Tips From the Trenches  

1. **The 70% Rule:** Keep utilization under 70% per account  
2. **Failover Frenzy:**  
   ```yaml  
   fallbacks:  
     - claude-3: [claude-2.1, jurassic-2]  
   ```
3. **Cost Watch:**  
   ```python  
   print(f"Daily spend: ${litellm.get_cost()}")  
   ```

## Your Turn: Let's Do This!  

Ready to banish 429 errors to the shadow realm? Here's your starter pack:  

1. Clone our battle-tested repo:  
   ```bash  
   git clone https://github.com/sofianhamiti/litellm-aws-fargate  
   ```

2. Deploy with one command:  
   ```bash  
   terraform apply -var="your_region=us-west-2"  
   ```

3. Test like a pro:  
   ```python  
   response = client.chat.completions.create(  
       model="claude-3-load-balance",  
       messages=[{"role": "user", "content": "How do I scale LLMs?"}]  
   )  
   ```

**Final Thought:** Remember that time you thought rate limits were inevitable? Yeah, me neither. LiteLLM + AWS Fargate changed the game—now go make some magic happen!  

Example 7
# Scaling LLM Applications with LiteLLM Proxy on AWS Fargate: A Multi-Account Strategy to Overcome Rate Limits  

Large Language Models (LLMs) have revolutionized AI applications, but scaling them while managing provider rate limits remains a critical challenge. This guide demonstrates how to deploy **LiteLLM Proxy** on AWS Fargate, connect it to multiple AWS Bedrock accounts, and implement a load-distribution strategy to avoid HTTP 429 errors.  

---

## Why LiteLLM?  

LiteLLM is an open-source tool that standardizes access to over 100 LLM APIs through a unified OpenAI-compatible interface. Its value lies in three core capabilities:  

1. **API Abstraction**: Simplifies integration by presenting a single endpoint for diverse models (AWS Bedrock, OpenAI, Anthropic, etc.)  
2. **Intelligent Routing**: Distributes requests across models/accounts using strategies like *least-busy* or *round-robin*  
3. **Enterprise Features**: Offers rate limit management, cost tracking, and automatic retries  

For AWS Bedrock users, LiteLLM solves a critical problem: **account-level rate limits**. By routing traffic through multiple accounts, organizations can effectively multiply their request quotas.  

---

## Architecture Overview  

![LiteLLM on AWS Fargate Architecture](https://github.com/sofianhamiti/litellm-aws-fargate/raw/main/docs/archition combines:  
- **AWS Fargate**: Hosts LiteLLM containers with auto-scaling  
- **Cross-Account IAM Roles**: Secure Bedrock access without credential management  
- **Application Load Balancer (ALB)**: Distributes incoming traffic  
- **CloudWatch**: Monitors performance and error rates  

---

## Step-by-Step Deployment  

### 1. Clone the Example Repository  
```bash  
git clone https://github.com/sofianhamiti/litellm-aws-fargate  
cd litellm-aws-fargate/terraform  
```

### 2. Configure LiteLLM for Multi-Account Routing  
Create `config.yaml`:  
```yaml  
model_list:  
  - model_name: claude-3-sonnet-account1  
    litellm_params:  
      model: bedrock/anthropic.claude-3-sonnet  
      aws_region: us-west-2  
      aws_role_arn: arn:aws:iam::111111111111:role/LiteLLM-Bedrock-Access  

  - model_name: claude-3-sonnet-account2  
    litellm_params:  
      model: bedrock/anthropic.claude-3-sonnet  
      aws_region: us-west-2  
      aws_role_arn: arn:aws:iam::222222222222:role/LiteLLM-Bedrock-Access  

router_settings:  
  routing_strategy: least-busy  
  fallbacks:  
    - claude-3-sonnet-account1: [claude-3-sonnet-account2]  
```

### 3. Deploy Infrastructure with Terraform  
```bash  
terraform init  
terraform apply -var="aws_region=us-west-2" \  
               -var="bedrock_account_ids=111111111111,222222222222"  
```

This creates:  
- ECS Fargate cluster with LiteLLM service  
- Internal Application Load Balancer  
- IAM roles for cross-account Bedrock access  

---

## Multi-Account Load Distribution  

### IAM Role Configuration  
For each Bedrock account, create a role with:  

**Trust Policy** (allow main account):  
```json  
{  
  "Version": "2012-10-17",  
  "Statement": [{  
    "Effect": "Allow",  
    "Principal": {"AWS": "arn:aws:iam::MAIN_ACCOUNT_ID:root"},  
    "Action": "sts:AssumeRole"  
  }]  
}  
```

**Permissions Policy** (Bedrock access):  
```json  
{  
  "Version": "2012-10-17",  
  "Statement": [{  
    "Effect": "Allow",  
    "Action": ["bedrock:InvokeModel"],  
    "Resource": "*"  
  }]  
}  
```

### Load-Balancing Strategy  
LiteLLM's `least-busy` router:  
1. Tracks active requests per model deployment  
2. Routes new requests to the least utilized endpoint  
3. Falls back to secondary accounts on 429 errors  

```yaml  
router_settings:  
  routing_strategy: least-busy  
  health_check_interval: 30  
  timeout: 30  
  retries: 3  
```

---

## Making Requests  

### Python Client Example  
```python  
from openai import OpenAI  

client = OpenAI(  
    base_url="http://litellm-alb-1234567890.us-west-2.elb.amazonaws.com",  
    api_key="sk-1234"  
)  

response = client.chat.completions.create(  
    model="claude-3-sonnet",  
    messages=[{"role": "user", "content": "Explain quantum entanglement"}]  
)  
```

### cURL Example  
```bash  
curl -X POST "http://litellm-alb-1234567890.us-west-2.elb.amazonaws.com/v1/chat/completions" \  
  -H "Authorization: Bearer sk-1234" \  
  -d '{  
    "model": "claude-3-sonnet",  
    "messages": [{"role": "user", "content": "Explain quantum computing"}]  
  }'  
```

---

## Key Benefits  

1. **Scalability**: Distribute load across N accounts for Nx quota capacity  
2. **Cost Efficiency**: Route to cost-optimized models/accounts  
3. **Zero Downtime**: Auto-scaling Fargate tasks handle traffic spikes  
4. **Security**: IAM roles eliminate credential management  

---

## Conclusion  

This architecture solves LLM rate limiting through:  
- **Multi-Account Load Distribution**: Multiply Bedrock quotas via IAM role chaining  
- **Unified API Surface**: Maintain compatibility with OpenAI-based clients  
- **Cost-Effective Scaling**: Combine reserved capacity across accounts  

To extend this solution:  
1. Implement request caching with Amazon ElastiCache  
2. Add regional failover using Route53  
3. Enable detailed usage tracking with CloudWatch Metrics  

For the complete code and Terraform templates, visit the [GitHub repository](https://github.com/sofianhamiti/litellm-aws-fargate).  
