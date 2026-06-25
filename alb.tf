# ================================================================= #
# 1. FIREWALL RULE: SECURITY GROUP FOR THE PUBLIC LOAD BALANCER
# ================================================================= #
resource "aws_security_group" "alb_sg" {
  name        = "production-alb-sg"
  description = "TCP/IP Layer 4 Firewall: Allow public HTTP web traffic entry"
  vpc_id      = aws_vpc.custom_vpc.id

  # Inbound: Allow standard web browser requests (TCP Port 80) from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Allow the ALB to send traffic to your backend servers anywhere inside the VPC
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "prod-alb-security-group" }
}

# ================================================================= #
# 2. THE APPLICATION LOAD BALANCER (ALB CORE)
# ================================================================= #
resource "aws_lb" "external_alb" {
  name               = "production-external-alb"
  internal           = false # Makes it public-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  # Cross-Zone High Availability: Spans both custom public subnets
  subnets = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = { Name = "prod-external-alb" }
}

# ================================================================= #
# 3. THE TARGET GROUP & NETWORK HEALTH PROBE
# ================================================================= #
resource "aws_lb_target_group" "app_target_group" {
  name     = "production-app-target-group"
  port     = 5000 # The internal custom TCP port where our Flask app will listen
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom_vpc.id

  # Automated Layer 7 Health Check configuration
  health_check {
    path                = "/"
    port                = "5000"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = { Name = "prod-app-target-group" }
}

# ================================================================= #
# 4. THE ALB HTTP ROUTING LISTENER
# ================================================================= #
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.external_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # Forward rule: Take incoming port 80 traffic and route it straight to the target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}