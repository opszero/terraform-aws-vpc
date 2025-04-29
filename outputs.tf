output "vpc_id" {
  value       = join("", aws_vpc.default[*].id)
  description = "The ID of the VPC."
}

output "vpc_arn" {
  value       = join("", aws_vpc.default[*].arn)
  description = "The ARN of the VPC"
}

output "vpc_cidr_block" {
  value       = join("", aws_vpc.default[*].cidr_block)
  description = "The CIDR block of the VPC."
}

output "ipv6_cidr_block" {
  value       = join("", aws_vpc.default[*].ipv6_cidr_block)
  description = "The IPv6 CIDR block."
}

output "vpc_ipv6_association_id" {
  value       = join("", aws_vpc.default[*].ipv6_association_id)
  description = "The association ID for the IPv6 CIDR block."
}

output "ipv6_cidr_block_network_border_group" {
  value       = join("", aws_vpc.default[*].ipv6_cidr_block_network_border_group)
  description = "The IPv6 Network Border Group Zone name"
}

output "vpc_main_route_table_id" {
  value       = join("", aws_vpc.default[*].main_route_table_id)
  description = "The ID of the main route table associated with this VPC."
}

output "vpc_default_network_acl_id" {
  value       = join("", aws_vpc.default[*].default_network_acl_id)
  description = "The ID of the network ACL created by default on VPC creation."
}

output "vpc_default_security_group_id" {
  value       = join("", aws_vpc.default[*].default_security_group_id)
  description = "The ID of the security group created by default on VPC creation."
}

output "vpc_default_route_table_id" {
  value       = join("", aws_vpc.default[*].default_route_table_id)
  description = "The ID of the route table created by default on VPC creation."
}

output "tags" {
  value       = aws_vpc.default[0].tags
  description = "A mapping of tags to assign to the resource."
}

output "igw_id" {
  value       = join("", aws_internet_gateway.default[*].id)
  description = "The ID of the Internet Gateway."
}

output "ipv6_egress_only_igw_id" {
  value       = join("", aws_egress_only_internet_gateway.default[*].id)
  description = "The ID of the egress-only Internet Gateway"
}

output "arn" {
  value       = join("", aws_flow_log.vpc_flow_log[*].arn)
  description = "Amazon Resource Name (ARN) of VPC"
}

output "dhcp_options_id" {
  value       = join("", aws_vpc.default[*].dhcp_options_id)
  description = "The ID of the DHCP options set associated with the VPC."
}

output "enable_dns_support" {
  value       = join("", aws_vpc.default[*].enable_dns_support)
  description = "Indicates whether DNS support is enabled."
}

output "enable_dns_hostnames" {
  value       = join("", aws_vpc.default[*].enable_dns_hostnames)
  description = "Indicates whether DNS hostnames are enabled."
}

output "instance_tenancy" {
  value       = join("", aws_vpc.default[*].instance_tenancy)
  description = "The tenancy of instances launched into the VPC."
}

output "igw_owner_id" {
  value       = join("", aws_internet_gateway.default[*].owner_id)
  description = "The ID of the AWS account that owns the Internet Gateway."
}

output "log_destination" {
  value       = join("", aws_flow_log.vpc_flow_log[*].log_destination)
  description = "The ARN of the destination for VPC flow logs."
}

output "log_format" {
  value       = join("", aws_flow_log.vpc_flow_log[*].log_format)
  description = "The log format for VPC flow logs."
}

output "log_group_name" {
  value       = join("", aws_flow_log.vpc_flow_log[*].log_group_name)
  description = "The name of the CloudWatch log group for VPC flow logs."
}

output "traffic_type" {
  value       = join("", aws_flow_log.vpc_flow_log[*].traffic_type)
  description = "The type of traffic captured (accept, reject, all)."
}





