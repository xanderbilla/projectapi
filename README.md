# ProjectAPI

A simple API application for a to-do list, focusing on deployment and the use of DevOps tools.

## API Reference

API Endpoint - [https://d3iklkly37bv64.cloudfront.net/health](https://d3iklkly37bv64.cloudfront.net/health")

| Endpoint                  | Method | Description                  |
| :------------------------ | :----- | :--------------------------- |
| `/health`                 | GET    | Get the health status        |
| `/tasks`                  | GET    | Get all tasks                |
| `/tasks`                  | POST   | Create a new task            |
| `/tasks/{id}`             | GET    | Get a specific task by ID    |
| `/tasks/{id}`             | PUT    | Update a specific task by ID |
| `/search?status={status}` | GET    | Search by status             |

## Environment Variables

To run this project, you will need to add the following environment variables to your `.env` file:

- `MONGO_URI`

## Workflow

### Continuous Integration/Continuous Deployment (CI/CD)

- **GitHub Actions**: Used for automating the build and deployment process.

### Containerization

- **Docker**: To containerize the application for consistent environments across different stages of development and deployment.

### Cloud Services

- **[AWS](https://aws.amazon.com)**: Used for hosting the application and database.

### Monitoring and Logging

- **[AWS CloudWatch](https://aws.amazon.com/cloudwatch)**: For monitoring the application.

## Architecture

![workflow](https://xanderbilla.s3.ap-south-1.amazonaws.com/projects/project-flow.png)

To deploy this application, the following DevOps tools and resources were used:

- **GitHub Repository**: [projectapi](https://www.github.com/xanderbilla/projectapi) is used to store the project code written in Java.
- **GitHub Actions**: CI/CD Pipeline used to build the Docker image and infrastructure.
- **Elastic Container Registry (ECR)**: Stores the Docker image.
- **Elastic Cloud Compute (EC2)**: An IaaS platform used to deploy the application.
- **AWS Secret Manager**: Stores sensitive data (e.g., `MONGO_URI`).
- **AWS System Manager**: Updates running containers when a new image is pushed to ECR, using a CloudWatch event bridge rule.
- **Application Load Balancer**: Balances traffic and is connected with CloudFront to cache traffic and secure it using SSL/TLS.

## About this project

This project is set up on Amazon Web Services and integrated with [GitHub Actions](https://docker.com). It includes a Java Spring Boot application for a backend to-do application. The GitHub Action builds the [Docker](https://docker.com) image and pushes it to the ECR repository. If the repository does not exist, it is created automatically and named `myprojectapi`.

In the AWS environment, a [VPC](https://aws.amazon.com/vpc/) is created with multiple availability zones and subnets containing multiple EC2 instances (two in this case). The VPC has internet access.

[EC2](https://aws.amazon.com/ec2/) instances are created with a role that allows access to SSM Document, secrets from AWS Secret Manager, and ECR read-only permission to download Docker images from ECR.

Initially, the EC2 instance uses user data to run and download necessary packages and run the container. It installs the [Amazon SSM Agent](https://docs.aws.amazon.com/systems-manager/latest/userguide/agent-install-al2.html), Docker, and Python.

The EC2 instance downloads the image from ECR and runs the container. If there is an updated image on ECR, a CloudWatch event triggers an update, running a script from the SSM document to stop the running container and replace it with the new one.

An [Application Load Balancer](https://aws.amazon.com/elasticloadbalancing/application-load-balancer/) handles the load on EC2 instances and is attached to [CloudFront](https://aws.amazon.com/cloudfront/) to provide a secure and smooth connection, also used for caching GET requests.

All events are logged in [CloudWatch](https://aws.amazon.com/cloudwatch) for ALB, EC2 instances, and CloudFront.

This entire infrastructure is created using Terraform, with the state stored in an S3 bucket and locks in DynamoDB.

## Setup project in your cloud environment

To run this project in your AWS cloud environment:

1. [Click here](https://github.com/xanderbilla/projectapi/fork) to fork the repository.
2. Go to **Repository Settings > Security and variables > Actions** and add the following environment variables:

| Variable Name           | Description                             |
| ----------------------- | --------------------------------------- |
| `AWS_ACCESS_KEY_ID`     | AWS access key ID                       |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key                   |

3. Go to the **Actions** tab and run the jobs manually for the first time to set up the infrastructure in your cloud environment.

> Once the environment is set, any new changes detected in the source code will update the Docker image on ECR, triggering an event to update the container with the new image.

## Usage/Examples

```javascript
import axios from "axios";

const getTaskById = async (id) => {
  try {
    const response = await axios.get(`/tasks/${id}`);
    console.log("Task:", response.data);
  } catch (error) {
    console.error("Error fetching the task:", error);
  }
};

// Usage example
getTaskById(1);
```

## Run Application Locally (Recommended using Docker)

Clone the project:

```bash
git clone https://github.com/xanderbilla/projectapi
```

Go to the project directory:

```bash
cd projectapi
```

Build the project image:

```bash
docker build -t spring-image .
```

Run the application:

```bash
docker run -d -p 8080:8080 -e MONGO_URI="mongodb+srv://YOUR-DB-LINK/projectapi" --name spring-app spring-image
```

## References

[Github Actions Docs](https://docs.github.com/actions)
[AWS Docs](https://docs.aws.amazon.com/)
[Hashicoprs docs](https://developer.hashicorp.com/terraform/docs)
[Docker Docs](https://docs.docker.com)

## Authors

[Vikas Singh](https://www.github.com/xanderbilla)

[Follow the link to know about me](https://xanderbilla.com)
