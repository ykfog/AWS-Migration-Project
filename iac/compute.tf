data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -xe
    dnf update -y
    dnf install -y nodejs
    mkdir -p /opt/app && cd /opt/app
    cat > server.js <<'JS'
    const http = require('http');
    const PORT = ${var.app_port};
    const server = http.createServer((req, res) => {
      if (req.url === '/health') { res.writeHead(200); return res.end('ok'); }
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.end('<h1>Student Information System</h1><p>Migrated to AWS - secure app tier (private subnet).</p>');
    });
    server.listen(PORT, () => console.log('listening on ' + PORT));
    JS
    cat > /etc/systemd/system/app.service <<'UNIT'
    [Unit]
    Description=Student Info App
    After=network.target
    [Service]
    ExecStart=/usr/bin/node /opt/app/server.js
    Restart=always
    User=root
    [Install]
    WantedBy=multi-user.target
    UNIT
    systemctl daemon-reload
    systemctl enable --now app.service
  EOF
  )
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type
  user_data     = local.user_data

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-app-instance" }
  }
}

resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id
  tags               = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }
  tags = { Name = "${var.project_name}-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  vpc_zone_identifier = aws_subnet.app[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-asg"
    propagate_at_launch = true
  }
}

# ---- Optional HTTPS:443 listener (self-signed cert from tls.tf) ----
# Gated by var.enable_https. Forwards to the same target group as HTTP.
# Requires acm:ImportCertificate (may be SCP-blocked in the sandbox).
resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.imported_cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
