# tfvpc2apache
This is a project using Terraform to automate he creation of an apache webserver in a private vpc connected to a private and public subnet, igw, eip and  

**How did I create the project**
Create a VPC
Create Internet Gateway
Create custom Route Table
Create a subnet
Associate Subnet with Route Table
Create Security Group to allow port 22, 80 amd 443 
Assign an EIP
Create an instance and Install/Enable Apache.
