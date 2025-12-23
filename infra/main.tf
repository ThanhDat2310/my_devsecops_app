provider "aws" {
    region = "us-east-1" 
}

# 1.Create Security Group
resource "aws_security_group" "web_sg" {
    name        = "devsecops-sg"
    description = "Allow HTTP and SSH"
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
#2. Make the virtual EC2
resource "aws_instance" "web_server" {
    ami           = "ami-0c7217cdde317cfec"
    instance_type = "t2.micro"
    key_name      = "devsecops-key"
    security_groups =[aws_security_group.web_sg.name]

    #User Data: Script automatically run when start to install Docker
    user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update -y 
                sudo apt-get install docker.io -y
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker ubuntu
                EOF
    
    tags = {
        Name = "DevSecOps-Server"
    }
}
# Export to IP of Server to know to access
output "public_ip" {
    value = aws_instance.web_server.public_ip
}
