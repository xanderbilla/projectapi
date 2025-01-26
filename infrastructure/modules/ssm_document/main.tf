resource "aws_ssm_document" "run_command" {
    name          = var.document_name
    document_type = "Command"

    content = jsonencode({
        schemaVersion = "2.2"
        description   = "Run shell script on EC2"
        mainSteps = [
            {
                action = "aws:runShellScript"
                name   = "runShellScript"
                inputs = {
                    runCommand = [
                        "sudo docker stop spring-app || true",
                        "sudo docker rm -f spring-app || true",
                        "sudo docker rmi -f my-spring-image || true",
                        "caller=$(aws sts get-caller-identity --query 'Account' --output text)",
                        "aws ecr get-login-password --region ap-south-1 | sudo docker login --username AWS --password-stdin $caller.dkr.ecr.ap-south-1.amazonaws.com",
                        "sudo docker pull $caller.dkr.ecr.ap-south-1.amazonaws.com/myprojectapi:latest",
                        "sudo docker tag $caller.dkr.ecr.ap-south-1.amazonaws.com/myprojectapi my-spring-image",
                        "sudo docker rmi -f $caller.dkr.ecr.ap-south-1.amazonaws.com/myprojectapi:latest",
                        "secret=$(aws secretsmanager get-secret-value --secret-id mongo/connection-url --query 'SecretString' --output text | jq -r .MONGO_URI)",
                        "sudo docker run -d -p 8080:8080 -e MONGO_URI=$secret --name spring-app my-spring-image"
                    ]
                }
            }
        ]
    })
}