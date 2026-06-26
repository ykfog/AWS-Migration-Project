# =========================================================================
# APPLICATION LOAD BALANCER & HTTPS LISTENERS
# =========================================================================
resource "aws_lb" "app_alb" {
  name               = "mmu-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id] # Attached your public SG
  # subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id] # Add your subnets here
}

# 1. The Secure HTTPS Listener (Port 443)
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  
  # CRITICAL: This is where you attach the certificate from security.tf
  certificate_arn   = aws_acm_certificate.imported_cert.arn

  default_action {
    type             = "forward"
    # target_group_arn = aws_lb_target_group.app_tg.arn # Forward to your Node.js instances
  }
}

# 2. The HTTP to HTTPS Redirect (Port 80)
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301" # Permanent redirect
    }
  }
}
