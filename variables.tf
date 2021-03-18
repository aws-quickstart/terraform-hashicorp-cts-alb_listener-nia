variable "services" {
  description = "Consul services monitored by Consul-Terraform-Sync"
  type = map(
    object({
      id        = string
      name      = string
      kind      = string
      address   = string
      port      = number
      meta      = map(string)
      tags      = list(string)
      namespace = string
      status    = string

      node                  = string
      node_id               = string
      node_address          = string
      node_datacenter       = string
      node_tagged_addresses = map(string)
      node_meta             = map(string)

      cts_user_defined_meta = map(string)
    })
  )
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to attach a target group for Consul ingress gateway."
}

variable "target_group_health_check" {
  description = "Health check attributes for target group. CTS sets port based on ingress gateway service metadata. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group#enabled for additional parmaeters."
  type = object({
    enabled             = bool
    interval            = number
    path                = string
    timeout             = number
    healthy_threshold   = number
    unhealthy_threshold = number
    matcher             = string
  })

  validation {
    condition     = var.target_group_health_check.interval >= 5 && var.target_group_health_check.interval <= 300
    error_message = "The approximate amount of time, in seconds, between health checks of an individual target. Minimum value 5 seconds, Maximum value 300 seconds."
  }

  validation {
    condition     = var.target_group_health_check.timeout >= 2 && var.target_group_health_check.timeout <= 120
    error_message = "The amount of time, in seconds, during which no response means a failed health check. For Application Load Balancers, the range is 2 to 120 seconds."
  }
}

variable "listener_arn" {
  type        = string
  description = "Listener ARN on Application Load Balancer for Consul ingress gateway listener rule."
}

variable "listener_rule_priority" {
  type        = number
  default     = 1
  description = "Priority of listener rule between 1 to 50000"
  validation {
    condition     = var.listener_rule_priority > 0 && var.listener_rule_priority < 50000
    error_message = "The priority of listener rule must between 1 to 50000."
  }
}

locals {
  name = distinct([
    for service, service_data in var.services :
    service_data.name if service_data.kind == "ingress-gateway"
  ])

  ip_addresses = toset([
    for service, service_data in var.services :
    replace(replace(split(".", service_data.node)[0], "ip-", ""), "-", ".") if service_data.kind == "ingress-gateway"
  ])

  port = distinct([
    for service, service_data in var.services :
    service_data.port if service_data.kind == "ingress-gateway"
  ])

  datacenter = distinct([
    for service, service_data in var.services :
    service_data.node_datacenter if service_data.kind == "ingress-gateway"
  ])


  // Below parses CTS user-defined metadata for listener group conditions.
  // You can only define one set of the condition blocks.
  // For more information, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule#host_header.

  // Get a list of unique host headers defined by CTS services configuration
  // Must be of format: host_header = "[\"test.hello-world.com\"]"
  host_headers = flatten([
    for value in compact(distinct([
      for service, service_data in var.services :
      try(service_data.cts_user_defined_meta.host_header, "") if service_data.kind != "ingress-gateway"
    ])) :
    jsondecode(value)
  ])

  // Get a list of unique path patterns defined by CTS services configuration
  // Must be of format: path_pattern = "[\"/test\"]"
  path_patterns = flatten([
    for value in compact(distinct([
      for service, service_data in var.services :
      try(service_data.cts_user_defined_meta.path_pattern, "") if service_data.kind != "ingress-gateway"
    ])) :
    jsondecode(value)
  ])

  // Get a list of unique http_request_methods defined by CTS services configuration
  // Must be of format: http_request_method = "[\"POST\"]"
  http_request_methods = flatten([
    for value in compact(distinct([
      for service, service_data in var.services :
      try(service_data.cts_user_defined_meta.http_request_method, "") if service_data.kind != "ingress-gateway"
    ])) :
    jsondecode(value)
  ])

  // Get a list of unique source IPs defined by CTS services configuration
  // Must be of format: source_ip    = "[\"10.0.0.4/32\"]"
  source_ips = flatten([
    for value in compact(distinct([
      for service, service_data in var.services :
      try(service_data.cts_user_defined_meta.source_ip, "") if service_data.kind != "ingress-gateway"
    ])) :
    jsondecode(value)
  ])

  // Get a unique http_header_name defined by CTS services configuration.
  // You can only have one named defined in the service!
  // Must be of format: http_header_name   = "X-Forwarded-For"
  http_header_name = compact(distinct([
    for service, service_data in var.services :
    try(service_data.cts_user_defined_meta.http_header_name, "") if service_data.kind != "ingress-gateway"
  ]))

  // Get a list of http_header_values defined by CTS services configuration
  // Must be of format: http_header_values = "[\"192.168.1.*\"]"
  http_header_values = flatten([
    for value in compact(distinct([
      for service, service_data in var.services :
      try(service_data.cts_user_defined_meta.http_header_values, "") if service_data.kind != "ingress-gateway"
    ])) :
    jsondecode(value)
  ])

  // Combine the http_header_values to the name of the header.
  http_headers = length(local.http_header_name) > 0 ? map(local.http_header_name.0, local.http_header_values) : {}

  // Get a list of unique query_strings defined by CTS services configuration
  // Must be of format: query_string = "key,value"
  query_strings = compact(distinct([
    for service, service_data in var.services :
    try(service_data.cts_user_defined_meta.query_string, "") if service_data.kind != "ingress-gateway"
  ]))
}
