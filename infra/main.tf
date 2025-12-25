provider "aws" {
  region = "us-east-1"
}

# 1. Tạo Security Group
resource "aws_security_group" "web_sg" {
  name        = "devsecops-sg-v2"
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

# --- PHẦN MỚI: TỰ ĐỘNG TẠO KEY PAIR ---

# 2. Tạo một Private Key mới (thay toán thuật RSA)
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 3. Đẩy Public Key lên AWS để tạo Key Pair
resource "aws_key_pair" "kp" {
  key_name   = "my-terraform-key"       # Tên Key trên AWS
  public_key = tls_private_key.pk.public_key_openssh
}

# 4. Lưu Private Key vào máy local (file .pem)
resource "local_file" "ssh_key" {
  filename = "${path.module}/devsecops-key.pem"
  content  = tls_private_key.pk.private_key_pem
  file_permission = "0400" # Cấp quyền chỉ đọc (quan trọng cho SSH)
}

# ---------------------------------------

# 5. Tạo máy ảo EC2
resource "aws_instance" "web_server" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 @ us-east-1
  instance_type = "t2.micro"
  
  # Dùng Key Pair vừa tạo ở trên
  key_name      = aws_key_pair.kp.key_name
  
  security_groups = [aws_security_group.web_sg.name]

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

output "public_ip" {
  value = aws_instance.web_server.public_ip
}
