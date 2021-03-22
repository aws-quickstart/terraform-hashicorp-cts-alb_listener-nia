# terraform-consul_sync-aws-alb_listener_rule-nia

The Consul-Terraform-Sync (CTS) module creates a listener rule and target group for an AWS Application Load Balancer. When the rule condition is met, traffic is forwarded to a Consul ingress gateway.

## Authors

- Rosemary Wang

## Prerequisites

- [Consul-Terraform-Sync](https://learn.hashicorp.com/collections/consul/network-infrastructure-automation) v0.1.0-beta

- [HashiCorp Consul](https://learn.hashicorp.com/consul) v1.9+
    - [Ingress gateway](https://www.consul.io/docs/connect/config-entries/ingress-gateway)
    - [Service registration](https://www.consul.io/docs/connect)

- [HashiCorp Terraform](https://learn.hashicorp.com/terraform) v0.14+

## Usage

The module primarily uses Consul-Terraform-Sync user metadata
to build the listener rule conditions to the Consul ingress gateway
target group.

You can use this module in Consul-Terraform-Sync with a service
configuration for the Consul ingress gateway, any of its services
for routing, and a task definition.

```hcl
service {
  name        = "ingress-gateway"
  datacenter  = "cloud"
  description = "all instances of the service ingress-gateway in datacenter cloud"
  cts_user_defined_meta = {}
}

service {
  name        = "my-application"
  datacenter  = "cloud"
  description = "all instances of the service my-application in datacenter cloud"
  cts_user_defined_meta = {
    host_header = "[\"test.hello-world.com\"]"
  }
}

task {
  name        = "ingress"
  description = "send traffic to ingress gateway for my-application"
  providers   = ["aws"]
  services    = ["my-application", "ingress-gateway"]
  source      = "aws-quickstart/alb_listener_rule/aws"
  version     = "0.1.0" # insert version
  variable_files = [] # define file with required variables
}
```

Exactly one of the following must be set per listener rule conditions:

- Host header
- HTTP request method
- HTTP header
- Path pattern
- Query string
- Source IP

The services behind the ingress gateway should include 
`cts_user_defined_meta`](https://www.consul.io/docs/nia/configuration#cts_user_defined_meta).
The metadata fields use a map of strings. For example, in Consul-Terraform-Sync configuration,
you can set the conditions for `my-application` service.

```hcl
service {
  name        = "my-application"
  datacenter  = "cloud"
  description = "all instances of the service my-application in datacenter cloud"
  cts_user_defined_meta = {
    # You must set exactly one of the following:
    host_header = "[\"test.hello-world.com\"]"
    # path_pattern = "[\"/test\"]"
    # source_ip    = "[\"10.0.0.4/32\"]"
    # http_request_method = "[\"POST\"]"
    # http_header_name   = "X-Forwarded-For"
    # http_header_values = "[\"192.168.1.*\"]"
    # query_string = "key,value"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | 0.14 or later |
| [AWS provider for Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest) | 3.32 or later |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| listener\_arn | Listener ARN on Application Load Balancer for Consul ingress gateway listener rule. | `string` | n/a | yes |
| listener\_rule\_priority | Priority of listener rule, between 1 and 50000. | `number` | `1` | no |
| services | Consul services monitored by CTS. | <pre>map(<br>    object({<br>      id        = string<br>      name      = string<br>      kind      = string<br>      address   = string<br>      port      = number<br>      meta      = map(string)<br>      tags      = list(string)<br>      namespace = string<br>      status    = string<br><br>      node                  = string<br>      node_id               = string<br>      node_address          = string<br>      node_datacenter       = string<br>      node_tagged_addresses = map(string)<br>      node_meta             = map(string)<br><br>      cts_user_defined_meta = map(string)<br>    })<br>  )</pre> | n/a | yes |
| target\_group\_health\_check | Health check attributes for target group. CTS sets port based on ingress gateway service metadata. For additional parameters, see [Resource: aws_lb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group#enabled). | <pre>object({<br>    enabled             = bool<br>    interval            = number<br>    path                = string<br>    timeout             = number<br>    healthy_threshold   = number<br>    unhealthy_threshold = number<br>    matcher             = string<br>  })</pre> | n/a | yes |
| vpc\_id | VPC ID to attach a target group for Consul ingress gateway. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| consul\_ingress\_listener\_rule\_arn | Amazon Resource Number (ARN) of the listener rule for Consul ingress gateway. |
| consul\_ingress\_target\_group\_arn | Target group ARN for Consul ingress gateway. |
