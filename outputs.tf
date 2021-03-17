output "consul_ingress_listener_rule_arn" {
  value       = aws_lb_listener_rule.consul_ingress.arn
  description = "Listener rule ARN for Consul ingress gateway"
}

output "consul_ingress_target_group_arn" {
  value       = aws_lb_target_group.consul_ingress.arn
  description = "Target Group ARN for Consul ingress gateway"
}