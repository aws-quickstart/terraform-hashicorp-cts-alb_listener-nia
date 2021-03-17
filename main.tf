resource "aws_lb_target_group" "consul_ingress" {
  name        = "consul-ingress"
  port        = local.port.0
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = var.target_group_health_check.enabled
    interval            = var.target_group_health_check.interval
    path                = var.target_group_health_check.path
    timeout             = var.target_group_health_check.timeout
    healthy_threshold   = var.target_group_health_check.healthy_threshold
    unhealthy_threshold = var.target_group_health_check.unhealthy_threshold
    matcher             = var.target_group_health_check.matcher
  }
}

resource "aws_lb_target_group_attachment" "consul_ingress" {
  for_each          = local.ip_addresses
  target_group_arn  = aws_lb_target_group.consul_ingress.arn
  target_id         = each.value
  port              = local.port.0
  availability_zone = "all"
}

resource "aws_lb_listener_rule" "consul_ingress" {
  listener_arn = var.listener_arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.consul_ingress.arn
  }

  condition {
    dynamic "host_header" {
      for_each = length(local.host_headers) > 0 ? [local.host_headers] : []
      content {
        values = host_header.value
      }
    }

    dynamic "path_pattern" {
      for_each = length(local.path_patterns) > 0 ? [local.path_patterns] : []
      content {
        values = path_pattern.value
      }
    }
    dynamic "http_request_method" {
      for_each = length(local.http_request_methods) > 0 ? [local.http_request_methods] : []
      content {
        values = http_request_method.value
      }
    }

    dynamic "source_ip" {
      for_each = length(local.source_ips) > 0 ? [local.source_ips] : []
      content {
        values = source_ip.value
      }
    }

    dynamic "http_header" {
      for_each = local.http_headers
      content {
        http_header_name = http_header.key
        values           = http_header.value
      }
    }

    dynamic "query_string" {
      for_each = local.query_strings
      content {
        key   = split(",", query_string.value).0
        value = split(",", query_string.value).1
      }
    }
  }
}