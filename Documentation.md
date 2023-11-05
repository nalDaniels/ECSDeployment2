# Purpose:
To deploy a two-tier retail banking application using Elastic Container Service. 

# Steps to Deployment
## 1. Use Terraform to Create Infrastructure for Jenkins Manager and Agents
### Purpose:
Using Terraform to provision cloud infrastructure permits shareability and reuse. In addition to creating the instances, there is also an ability to install Jenkins on the first instance, Docker, Java, and the application's dependencies on the second instance, and Terraform and Java on the third instance via the user data field. 
### Process:
Without specifying the VPC, Terraform was able to smartly create the EC2 instances in the default VPC based on the subnet ID. 

On the instance for the Jenkins manager and Jenkins agent running Docker, I installed the following packages: Software-properties-common, which helps manage different repositories or sources of packages add-apt-repository -y ppa:deadsnakes/ppa, which allows us to install multiple versions of python python3.7 and python3.7-venv, which installs python3.7 and the virtual environment package, build-essentials, which allows you to build applications on Linux systems, libmysqlclient-dev, which installs the dependencies necessary for using a mySQL database, and python3.7-dev, which installs files required for running an application that uses python3.7.

Here is a link to my Terraform file: https://github.com/nalDaniels/ECSDeployment2/blob/main/main.tf

### Issues:
After applying the configurations, I received this error:
<img width="1057" alt="capacity error" src="https://github.com/nalDaniels/ECSDeployment2/assets/135375665/a9cf2502-bfff-4fec-8dc0-a93ebc3f3ded">
I resolved it by removing EC2 instances in availability zone us-east-1c. This serves as reminder that each availability zone has a limit on the number of launched t2.micro instances.
### Optimization:
Going forward, the application's dependencies should only be installed on the Jenkins agent running Docker since that is the only node actually building the application per the Jenkinsfile.

## 2. Create an RDS Database and Update Database URL
### Purpose:
Connecting the application to an RDS database will allow all instances to have access to the same information. It provides redundancy and an improved user experience by allowing sessions across instances to be consistent.
### Process:
I created a MySQL database, which is getting incoming requests from the application on port 3306.

## 3. Create a Dockerfile
### Purpose:
To create instructions on how to build an image of the retail banking application code and dependencies. 
### Process:
I created a second branch in my repository and created a dockerfile. Next, I added the changes to a staging environment, committed the changes, merged those changes to my main branch. To ensure that the build of the image was successful, I ran docker build and successfully created an image. 
### Optimization:
The dockerfile could have been separated into 2 dockerfiles - one for the web tier and one for the application tier.


## 4. Use Terraform to Provision Infrastructure for the Application
### Purpose:
Terraform allows you to create multiple resources or infrastructure without having to navigate through AWS services graphical user interface. 
### Process:
For organizational purposes, I separated my Terraform files into a file for the VPC infrastructure, ECS cluster, and load balancer. In my VPC.tf file, I set up two availability zones, us-east-1a and us-east-1b, within a VPC. In each zone, there is a public subnet and a private subnet. A public route table connects the two public subnets to the internet gateway, which provides the VPC access to the internet. A private route table connects the two private subnets to the public NAT gateway, which provides the private subnets access to the internet. Since the NAT gateway is in the public subnet, it requires an elastic IP address. The main.tf file configured a Elastic Container cluster, which emcompasses the services, the tasks, networking, and CloudWatch monitoring. A CloudWatch log group was created and associated with the task definition. The task definiton is a blueprint or template for the tasks or containers. It specifies the image, port (8000), and resources (1024 MiB Memory and 512 CPU units) allocated to the task. The tasks should be compatible with Fargate, have security groups, and monitor VPC traffic. In order to execute the task, I associated the ECSTaskExecutionRole to the task definition. Next, I created a ECS service for the cluster, which will create 2 tasks or containers based on the task definiton. The containers should run on Fargate in the private subnets. The tasks the service launches should be accessible on port 8000. To distribute traffic between the containers, I set up an application load balancer associated with the tasks created by the service. The load balancer's target group points to the IP addresses of the containers created by the service. The ALB is listening or taking incoming requests on port 80 and deployed between the public subnets. After creating the load balancer, it creates an URL for clients to access the application deployed on the containers. 

## 5. Create a Jenkins MultiBranch Pipeline
### Purpose:
Instead of using multiple applications to execute various stages of the CI/CD pipeline, Jenkins allows engineers to automate the pipeline through the use of a Jenkinsfile and plugins. 

Executing the pipeline on Jenkins agents enhances security since the workspace containing the application code and dependencies exists on the agents, which are only accessible through ssh connection. It also improves resource contention by distributing the load across multiple instances. Additionally, you can select the instance type for the agent based on the resources necessary to carry out the stages it is responsible for carrying out. 
### Process:
I created nodes
