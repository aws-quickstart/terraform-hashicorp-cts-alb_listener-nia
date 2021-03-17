output "listener_rule_arn" {
  value = module.listener_rule.consul_ingress_listener_rule_arn
}

output "target_group_arn" {
  value = module.listener_rule.consul_ingress_target_group_arn
}