# ================================================================= #
# 1. FIREWALL RULE: SECURITY GROUP FOR THE PRIVATE FLASK INSTANCES
# ================================================================= #
resource "aws_security_group" "instance_sg" {
  name        = "production-instance-sg"
  description = "TCP/IP Layer 4 Firewall: Restrict inbound access strictly to ALB targets"
  vpc_id      = aws_vpc.custom_vpc.id

  # CRITICAL SECURITY CONCEPT: Only allow incoming traffic if it originates from our ALB's Security Group
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Outbound: Allow instances to go out to the internet via the NAT Gateway for updates
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "prod-instance-security-group" }
}

# ================================================================= #
# 2. APPLICATION NODE 1 (Availability Zone A - Private Subnet)
# ================================================================= #
resource "aws_instance" "app_server_1" {
  ami                    = "ami-01811d4912b4ccb26" # Ubuntu 24.04 LTS standard image in ap-southeast-1
  instance_type          = "t2.micro"              # Free-tier eligible
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  # User Data Script: Automates system updates, installs Python Flask, and starts the app on Port 5000
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y python3-pip python3-flask
              
              cat << 'APP' > /home/ubuntu/app.py
              from flask import flask
              import socket
              app = Flask(__name__)
              @app.route('/')
              def home():
                  return f"<h1>Custom 3-Tier Architecture Live!</h1><p>Served by Private Instance ID: {socket.gethostname()}</p>"
              if __name__ == '__main__':
                  app.run(host='0.0.0.0', port=5000)
              APP
              
              python3 /home/ubuntu/app.py &
              EOF

  tags = { Name = "prod-flask-app-az-a" }
}

# ================================================================= #
# 3. APPLICATION NODE 2 (Availability Zone B - Private Subnet)
# ================================================================= #
resource "aws_instance" "app_server_2" {
  ami                    = "ami-01811d4912b4ccb26"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y python3-pip python3-flask
              
              cat << 'APP' > /home/ubuntu/app.py
              from flask import Flask
              import socket
              app = Flask(__name__)
              @app.route('/')
              def home():
                  return f"<h1>Custom 3-Tier Architecture Live!</h1><p>Served by Private Instance ID: {socket.gethostname()}</p>"
              if __name__ == '__main__':
                  app.run(host='0.0.0.0', port=5000)
              APP
              
              python3 /home/ubuntu/app.py &
              EOF

  tags = { Name = "prod-flask-app-az-b" }
}

# ================================================================= #
# 4. REGISTER THE EC2 NODES DIRECTLY INTO OUR ALB TARGET GROUP
# ================================================================= #
resource "aws_lb_target_group_attachment" "app_1_attach" {
  target_group_arn = aws_lb_target_group.app_target_group.arn
  target_id        = aws_instance.app_server_1.id
  port             = 5000
}

resource "aws_lb_target_group_attachment" "app_2_attach" {
  target_group_arn = aws_lb_target_group.app_target_group.arn
  target_id        = aws_instance.app_server_2.id
  port             = 5000
}

# ================================================================= #
# 5. OUTPUTS: Print the Public ALB DNS string to our terminal window
# ================================================================= #
output "alb_public_url" {
  description = "The public endpoint address used to hit your custom architecture"
  value       = "http://${aws_lb.external_alb.dns_name}"
}