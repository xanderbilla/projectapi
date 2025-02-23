# AWS DevOps To-Do API 

A scalable and fully automated API application for managing to-do lists, built with Java Spring Boot and deployed on AWS using DevOps best practices.

## API Reference

**Base URL:** [https://d3iklkly37bv64.cloudfront.net](https://d3iklkly37bv64.cloudfront.net)

| Endpoint                  | Method | Description                  |
|--------------------------|--------|------------------------------|
| `/health`                 | GET    | Checks application health    |
| `/tasks`                  | GET    | Retrieves all tasks          |
| `/tasks`                  | POST   | Creates a new task           |
| `/tasks/{id}`             | GET    | Retrieves a task by ID       |
| `/tasks/{id}`             | PUT    | Updates a task by ID         |
| `/search?status={status}` | GET    | Searches tasks by status     |

## Environment Variables

Ensure the following environment variable is set before running the application:

- `MONGO_URI`: MongoDB connection string

## Deployment Workflow

### CI/CD Automation

- **GitHub Actions** automates the build, test, and deployment process.
- **Docker** ensures environment consistency across development and production.
- **Terraform** provisions the cloud infrastructure.

### AWS Cloud Services

- **ECR**: Stores Docker images securely.
- **EC2**: Hosts and runs the application.
- **Secrets Manager**: Manages sensitive credentials.
- **Systems Manager (SSM)**: Automates container updates when a new image is pushed.
- **ALB (Application Load Balancer)**: Distributes traffic efficiently and integrates with CloudFront.
- **CloudFront**: Improves performance through caching and SSL/TLS security.
- **CloudWatch**: Monitors application logs and infrastructure events.

## Architecture Overview

![workflow](https://xanderbilla.s3.ap-south-1.amazonaws.com/projects/projectapi-flow.png)

### Infrastructure Details

- **VPC** with multiple availability zones and subnets.
- **EC2 Instances** configured with necessary roles for ECR, SSM, and Secrets Manager access.
- **CloudWatch Event Rules** trigger updates for new Docker images.
- **ALB** balances traffic across EC2 instances.
- **CloudFront** optimizes and secures content delivery.
- **Terraform** manages infrastructure as code (IaC), storing state in an **S3 bucket** with **DynamoDB** for state locking.

## Setting Up in Your AWS Environment

Before deployment, update the S3 bucket name in:

- [`infrastructure/main.tf`](https://github.com/xanderbilla/projectapi/blob/main/infrastructure/main.tf)
- [`deploy.yml`](https://github.com/xanderbilla/projectapi/blob/main/.github/workflows/deploy.yml) (lines 34 and 35)

### Deployment Steps:

1. **Fork the repository**: [Click here](https://github.com/xanderbilla/projectapi/fork)
2. **Set up GitHub Actions secrets**:

   | Variable Name           | Description                      |
   |-------------------------|----------------------------------|
   | `AWS_ACCESS_KEY_ID`     | AWS access key ID               |
   | `AWS_SECRET_ACCESS_KEY` | AWS secret access key           |

3. **Run the GitHub Actions workflow manually** to set up infrastructure and deploy the application.

> Subsequent changes to the repository will trigger automatic deployment of the updated application.

## Example Usage

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

// Example usage
getTaskById(1);
```

## Running Locally with Docker

Clone the repository:

```bash
git clone https://github.com/xanderbilla/projectapi
```

Navigate to the project directory:

```bash
cd projectapi
```

Build and run the application in a Docker container:

```bash
docker build -t projectapi .
docker run -d -p 8080:8080 -e MONGO_URI="your-mongodb-uri" --name projectapi projectapi
```

## Documentation and References

- [GitHub Actions Docs](https://docs.github.com/actions)
- [AWS Documentation](https://docs.aws.amazon.com/)
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Docker Documentation](https://docs.docker.com)

## Author

[Vikas Singh](https://www.github.com/xanderbilla)

[More About Me](https://xanderbilla.com)

