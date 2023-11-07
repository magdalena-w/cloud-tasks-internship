resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb" "my_lb" {
  name               = "my-lb"
  internal           = false
  load_balancer_type = "application"
  enable_deletion_protection = false

  enable_http2      = true

  security_groups = ["${var.lb_sg_id}"]
  subnets         = var.subnet_ids
  tags = {
    Owner = "mwalesa"
    Project = "2023_internship_wro"
    Name = "lb_terraform_task"
  }
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    #target_group_arn = aws_lb_target_group.my_target_group.arn
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "Fixed response content. Hello from the load balancer."
    }
  }
}

resource "aws_lb_listener_rule" "my_rule" {
  listener_arn = aws_lb_listener.my_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}


resource "aws_launch_configuration" "my_launch_config" {
  name               = "my-launch-config"
  image_id           = "ami-047bb4163c506cd98"
  instance_type      = "t2.micro"
  security_groups    = ["${var.tg_sg_id}"]
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello from the scale set. " > /var/www/html/index.html
    systemctl start httpd
    systemctl enable httpd
    EOF
}

resource "aws_autoscaling_group" "my_asg"{
  name                      = "my-asg"
  launch_configuration      = aws_launch_configuration.my_launch_config.name
  min_size                  = 3
  max_size                  = 3
  desired_capacity          = 3
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true

  vpc_zone_identifier = var.subnet_ids

  target_group_arns = [aws_lb_target_group.my_target_group.arn]
}

