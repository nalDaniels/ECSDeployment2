# Purpose:
To deploy a two-tier retail banking application to containers using Elastic Container Service on Fargate. Terraform was used to create the infrastructure for Jenkins and the containers. To familiarize myself with using ECS service and private subnets to make our application for fault-tolerant and secure. 

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
For organizational purposes, I separated my Terraform files into a file for the VPC infrastructure, ECS cluster, and load balancer. In my VPC.tf file, I set up two availability zones, us-east-1a and us-east-1b, within a VPC. In each zone, there is a public subnet and a private subnet. A public route table connects the two public subnets to the internet gateway, which provides the VPC access to the internet. A private route table connects the two private subnets to the public NAT gateway, which provides the private subnets access to the internet. Since the NAT gateway is in the public subnet, it requires an elastic IP address. The main.tf file configured a Elastic Container cluster, which emcompasses the services, the tasks, networking, and CloudWatch monitoring. A CloudWatch log group was created and associated with the task definition. The task definiton is a blueprint or template for the tasks or containers. It specifies the image, port (8000), and resources (1024 MiB Memory and 512 CPU units) allocated to the task. The tasks should be compatible with Fargate, have security groups, and monitor VPC traffic. In order to execute the task, I associated the ECSTaskExecutionRole to the task definition. Next, I created a ECS service for the cluster, which will create 2 tasks or containers based on the task definiton. In the case, that one container failed, another one would be created. The service states that there should be 2 containers running at all times. The containers should run on Fargate in the private subnets. The tasks the service launches should be accessible on port 8000. To distribute traffic between the containers, I set up an application load balancer associated with the tasks created by the service. The load balancer's target group points to the IP addresses of the containers created by the service. The ALB is listening or taking incoming requests on port 80 and deployed between the public subnets. After creating the load balancer, it creates an URL for clients to access the application deployed on the containers. 

## 5. Create a Jenkins MultiBranch Pipeline
### Purpose:
Instead of using multiple applications to execute various stages of the CI/CD pipeline, Jenkins allows engineers to automate the pipeline through the use of a Jenkinsfile and plugins. 

Executing the pipeline on Jenkins agents enhances security since the workspace containing the application code and dependencies exists on the agents, which are only accessible through ssh connection. It also improves resource contention by distributing the load across multiple instances. Additionally, you can select the instance type for the agent based on the resources necessary to carry out the stages it is responsible for carrying out. 
### Process:
I created nodes for the Jenkins manager to connect to and execute the pipeline stages. In order for the pipeline to perform the Docker and Terraform related stages, I had to add plugins and credentials for Docker and AWS. 
### Pipeline:
After cloning the repository onto the nodes, a test stage ran, where a python virtual environment was created and an HTTP request was sent to the application in order to hopefully return a 200 response code. The build stage ran on the Jenkins agent running Docker. This stage determined whether the dockerfile was able to successfully build the image. Next, Docker logged into my Docker Hub and pushed the image to my repository. The Jenkins agent running Terraform initialized the directory with the .tf files for the application infrastructure, showed my configurations along with Terraform's, and created the infrastructure via Terraform apply.
### Issues:
My Docker build stage failed due to these errors: 
<img width="1035" alt="docker error" src="https://github.com/nalDaniels/ECSDeployment2/assets/135375665/21588f2d-1449-46e7-9e8f-eefaafc9d1e6">
Essentially, I did not install Docker as the root user. To resolve the issue, I ran sudo usermod -aG docker $USER, which added the docker group to the ubuntu user, and sudo reboot to restart the instance with the new changes.

<img width="1000" alt="database error" src="https://github.com/nalDaniels/ECSDeployment2/assets/135375665/15073b0d-52b4-4470-82aa-46a520f08f3b">
Since I previously created the image when I tested it out before running the Jenkins pipeline, the data was already loaded into the RDS database. Therefore, when I ran the build stage in Jenkins for the dockerfile with the line "RUN python load_data.py," it tried to reload the data, creating a duplicate entry. This caused an integrity error since there should only be one account with the same username and password.

# Successful Deployment
To access the application, I had to use the URL generated from the application load balancer. I was unable to access the application via the containers since they are in a private subnet with no public IP address. 
<img width="1433" alt="deployment success" src="https://github.com/nalDaniels/ECSDeployment2/assets/135375665/f368acb4-2beb-44d5-8aed-5436d7bc9f6c">

# Optimization
The infrastructure for the application is secure because the applications are in a private subnet, reducing likelihood of attacks from the Internet. The ECS service made the containers fault-tolerant. If a container goes down, another container will be created, ensuring there is always 2 containers running. However, since there is only one database the entire infrastructure is not fault-tolerant since an issue with the database would cause the application to go down. This can be resolved by created a backup database.

I would also suggest securing the architecture for the Terraform. From this design, anyone from the Internet can access our state files. We can add a nginx or apache server in the public subnet and place Terraform in an instance in the private subnet. At a higher level of security, a network control access list can be created for the subnets for the range of IP addresses of the engineers. 

Using Jenkins agents to execute the pipeline makes Jenkins more secure since the application code and files are solely on the Jenkins agents, which are only accessible via ssh. 

# System Design

![Plan Deployment 7 drawio (1)](https://github.com/nalDaniels/ECSDeployment2/assets/135375665/28a3907e-b12f-410a-8efb-f84e96acdd02)
