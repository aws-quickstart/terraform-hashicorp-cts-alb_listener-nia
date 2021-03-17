locals {
  module_name = "terraform-aws-listener-rule"

  tags = {
    module  = local.module_name
    purpose = "test"
  }
  test_name = "${local.module_name}-module-test"
}

data "aws_vpc" "selected" {
  default = true
}

data "aws_subnet_ids" "selected" {
  vpc_id = data.aws_vpc.selected.id
}

resource "aws_lb" "module_test" {
  name               = local.module_name
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.selected.ids

  enable_deletion_protection = false

  tags = local.tags
}

resource "aws_lb_listener" "module_test" {
  load_balancer_arn = aws_lb.module_test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}

module "listener_rule" {
  source       = "../"
  services     = var.services
  vpc_id       = data.aws_vpc.selected.id
  listener_arn = aws_lb_listener.module_test.arn
  target_group_health_check = {
    enabled             = true
    interval            = 150
    path                = "/health"
    port                = "traffic-port"
    timeout             = 6
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
}