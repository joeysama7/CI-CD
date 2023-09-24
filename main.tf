provider "aws" {
  region     = "us-east-1"
  profile = "joey"
}


# Create a VPC
resource "aws_vpc" "prodvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "production_vpc"
  }
}


# Create a subnet
resource "aws_subnet" "prodsubnet1" {
  vpc_id     = aws_vpc.prodvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "production_subnet"
  }
}

# Create an IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.prodvpc.id

  tags = {
    Name = "IGW_Production"
  }
}

# Create a Route table
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.prodvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }


  tags = {
    Name = "RouteTable"
  }
}

# Associate the subnet with the Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prodsubnet1.id
  route_table_id = aws_route_table.RT.id
}

# Create a security group for instance
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web server inbound traffic"
  vpc_id      = aws_vpc.prodvpc.id

  ingress {
    description      = "Web traffic from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # Any protocol/ Any IP Address
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG_allow_web"
  }
}

# Create an Instance and assign key pair
resource "aws_instance" "firstinstance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id      = aws_subnet.prodsubnet1.id
  key_name = "PublicKP"
  user_data = "${file("install_jenkins.sh")}"

  tags = {
    Name = "Jenkins_Server"
  }
}

resource "aws_instance" "secondinstance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id      = aws_subnet.prodsubnet1.id
  key_name = "PublicKP"
  user_data              =  "${file("install_tomcat.sh")}"

  tags = {
    Name = "Tomcat_Server"
  }
}

# Use data source to get a registered ubuntu ami
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Print the url of the Jenkins Server
output "Jenkins_Website_url" {
    value = join("", ["http://",aws_instance.firstinstance.public_ip, ":", "8080"])  
    description = "Jenkins server is first instance"
}

# print the url of the tomcat server
output "Tomcat_website_url1" {
  value     = join ("", ["http://", aws_instance.secondinstance.public_ip, ":", "8080"])
  description = "Tomcat Server is secondinstance"
}