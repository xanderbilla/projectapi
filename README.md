# ProjectAPI

A simple API application of to do list. Where the main focus is on deployment and use of devops tools.

## API Reference

| Endpoint                  | Method | Description                  |
| :------------------------ | :----- | :--------------------------- |
| `/health`                 | GET    | Get the health status        |
| `/tasks`                  | GET    | Get all tasks                |
| `/tasks`                  | POST   | Create a new task            |
| `/tasks/{id}`             | GET    | Get a specific task by ID    |
| `/tasks/{id}`             | PUT    | Update a specific task by ID |
| `/search?status={status}` | GET    | Search by status             |

## Environment Variables

To run this project, you will need to add the following environment variables to your .env file

`MONGO_URI`

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

## Run Application Locally (Recommended using docker)

Clone the project

```bash
  git clone https://github.com/xanderbilla/projectapi
```

Go to the project directory

```bash
  cd projectapi
```

Build the project image

```bash
  docker build -t spring-image .
```

Run the application

```bash
  docker run -d -p 8080:8080 -e MONGO_URI="mongodb+srv://YOUR-DB-LINK/projectapi" --name spring-app spring-image
```

## Workflow

### Continuous Integration/Continuous Deployment (CI/CD)

- **GitHub Actions**: Used for automating the build and deployment process.

### Containerization

- **Docker**: To containerize the application for consistent environments across different stages of development and deployment.

### Cloud Services

- **AWS**: Used for hosting the application and database.

### Monitoring and Logging

- **AWS Cloudwatch**: For monitoring application.

## Architecture

![workflow](https://xanderbilla.s3.ap-south-1.amazonaws.com/projects/projectapi-workflow.png)

To deploy this application, the following DevOps tools and resources were used:

**Github Repository** [projectapi](https://www.github.com/xanderbilla/projectapi) is used to store the the porject code written in Java Programming Language.

**Github Actions -** CI/CD Pipeline has been used to build the docker image, and infrastructure.

**Elastic Container Registry (ECR)** Stored the docker image

**Elastic Cloud Compute (EC2)** an IaaS platform has been used to deploy our application.

**AWS Secret Mangaer** has been used to store sensetive data (here in our case it's `MONGODB_URI`)

**AWS System Manager** has been used to update the running containers when a new image is pushed on ECR. This is achieved by using **cloudwatch event bridge** rule.

An **Application Load Balancer** is used to balance the traffic and then it is connected with **Cloudfront** to cache the tradfic and secure it using SSL/TLS.

# How this project work


# Setup project in your cloud environment

To run this project in your cloud environment -

[Click here](https://github.com/xanderbilla/projectapi/fork) to fork the repository.

Go to **Repository Setting > Security and variables > Actions** and add following environemnt - 

| Variable Name           | Description                             |
| ----------------------- | --------------------------------------- |
| `AWS_ACCESS_KEY_ID`     | AWS access key ID                       |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key                   |
| `ECR_REPOSITORY`        | ECR repository URL for Docker images    |

> [Then go to Actions tab run the jobs manually for the first time. That will set up the infrastructure in your cloud environment.]()

Once the environment is set any new chnages in the source code will update the docker image on ECR automatically,then an event will be triggered.

The triggered event will run a shell script in our running instance that will update the stop and re run the conatiner with new image.  

## Authors

[Vikas Singh](https://www.github.com/xanderbilla)

[Follow the link to know about me](https://xanderbilla.com)
