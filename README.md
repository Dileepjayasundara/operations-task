# Xeneta Operations Task

## Practical case: Deployable development environment

### Setting up local development environment using Docker
#### 1. Install Docker and Docker Compose
#### 2. Clone this repo
#### 3. Create a file named as `.env` in repo directory and add below variable with prefered values. Keep the `POSTGRES_HOST` value as `postgresql`
````
POSTGRES_DB="prefered-db-name"
POSTGRES_USER="prefered-db-username"
POSTGRES_PASSWORD="prefered db-password"
POSTGRES_HOST="postgresql"
````
#### 4. From Repo directory run below command to start application
````
docker-compose build && docker-compose up -d
````
By using Docker and Docker Compose, developers can set-up their local development environment within few seconds using a single command without worring about the related dependencies.


### Setting up development environment on AWS
#### 1. Clone this repo
#### 2. Create an AWS s3 bucket to store terraform state. Add the bucket name in `terraform/main.tf`
#### 3. Change `terraform/terraform.tfvars` file with prefered values.
#### 4. Run the following commands from terraform directory to provision the AWS resources
````
terraform init
terraform plan
terraform apply
````
#### 5. Add the following Github Actions secrets accordingly in GitHub repository
````
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_ACC_ID 
````
This will enable CICD pipeline on master branch. To change the values refer to `.github/workflows/main.yml` file.

### HighLevel Architecture Diagram
![HADiagram](https://user-images.githubusercontent.com/17748570/207953823-3479fa74-a6b1-41a8-9737-ea0f78c60533.png)

This AWS infrastructure is mainly proviosioned on three subnets considering the security aspects as well. It has used one public subenet to provision Elastic load balancer to maintain the high availablity of the application and one private subnets to provision ECS components and another private subnet to isolate RDS considering the security aspects. AWS Fargate Container service has been used in this deployment to run the containerzied application and to enable application scalability. Container service logs are configured access using AWS cloudwatch.

RDS credentials are store in AWS systems manager parameter store to access them from ECS containers in a secure way. Randomly generated password is configured for the RDS database while provisioning it from terrraform.

AWS ECR is used to store container images created through github Actions. Every commit on master branch will triger the CICD pipelines on GitHub Actions.
To change the values refer to `.github/workflows/main.yml` file in the repo.

##
## Case: Data ingestion pipeline

In this section we are seeking high-level answers, use a maximum of couple of paragraphs to answer the questions.

### Extended service

Imagine that for providing data to fuel this service, you need to receive and insert big batches of new prices, ranging within tens of thousands of items, conforming to a similar format. Each batch of items needs to be processed together, either all items go in, or none of them do.

Both the incoming data updates and requests for data can be highly sporadic - there might be large periods without much activity, followed by periods of heavy activity.

High availability is a strict requirement from the customers.

##### 1.How would you design the system?
With the provided information, The solution should implement on event driven architecture with serverless approach since data should processed whenever its available and compute resources should be get dynamically provisioned according to the required load. Lets consider when big batches of data files get uploaded to an AWS s3 as the incoming data source. 

AWS eventbridge service can be used to identify the event and generate a notification. Then the next concern is how we going to implement the data processing with serverless architecture. AWS batch service can be used with this scenario. AWS Fargate jobs are available as EventBridge targets. Using simple rules, we can match events and submit AWS Batch jobs in response to them. procesed data can be stored in RDS database for the application.

##### 2.How would you set up monitoring to identify bottlenecks as the load grows?

Cloudwatch service can be used to monitor the AWS batch service and the status of the jobs, job queues, get container insights etc. As we store processed data on RDS we can enable cloudwatch alarms with relevent threshold.

##### 3.How can those bottlenecks be addressed in the future?
As AWS batch service is designed to managed heavy batch processing workloads, we can configure our resource requirements for the Fagate or ec2 instances.
Database can be changed according to the future application design requirements.

### Additional questions

Here are a few possible scenarios where the system requirements change or the new functionality is required:

1. The batch updates have started to become very large, but the requirements for their processing time are strict.

There can be bottlenecks both in datasource resources and data processing resources. In data processing we can add more compute resource requirements or configure multi-node parallel jobs execution to reduce the processing time. If we are using S3 as the injection data injection source it's a best practice to leverage multipart uploads and using Amazon S3 Transfer Acceleration.
