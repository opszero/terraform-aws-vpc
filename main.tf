# Inside the module `vpc_module`
# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "default" {
  count                                = var.enabled ? 1 : 0
  cidr_block                           = var.ipam_pool_enable ? null : var.cidr_block
  ipv4_ipam_pool_id                    = var.ipv4_ipam_pool_id
  ipv4_netmask_length                  = var.ipv4_netmask_length
  ipv6_cidr_block                      = var.ipv6_cidr_block
  ipv6_ipam_pool_id                    = var.ipv6_ipam_pool_id
  ipv6_netmask_length                  = var.ipv6_netmask_length
  instance_tenancy                     = var.instance_tenancy
  enable_dns_hostnames                 = var.dns_hostnames_enabled
  enable_dns_support                   = var.dns_support_enabled
  assign_generated_ipv6_cidr_block     = var.assign_generated_ipv6_cidr_block
  ipv6_cidr_block_network_border_group = var.ipv6_cidr_block_network_border_group
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics
  tags = merge(
    var.tags,
    {
      Name = lookup(var.tags, "Name", var.name)
    }
  )

  lifecycle {
    # Ignore tags added by Kubernetes
    ignore_changes = [
      tags,
      tags["kubernetes.io"],
      tags["SubnetType"],
    ]
  }
}


resource "aws_vpc_ipv4_cidr_block_association" "default" {
  for_each   = toset(var.additional_cidr_block)
  vpc_id     = join("", aws_vpc.default[*].id)
  cidr_block = each.key
}

resource "aws_internet_gateway" "default" {
  count  = var.enabled ? 1 : 0
  vpc_id = join("", aws_vpc.default[*].id)
  tags = merge(
    var.tags,
    {
      Name = format("%s-igw", lookup(var.tags, "Name", "default"))
    }
  )

}

resource "aws_egress_only_internet_gateway" "default" {
  count  = var.enabled && var.enabled_ipv6_egress_only_internet_gateway ? 1 : 0
  vpc_id = join("", aws_vpc.default[*].id)
  tags   = var.tags
}

resource "aws_default_security_group" "default" {
  count  = var.enabled && var.restrict_default_sg == true ? 1 : 0
  vpc_id = join("", aws_vpc.default[*].id)
  dynamic "ingress" {
    for_each = var.default_security_group_ingress
    content {
      self             = lookup(ingress.value, "self", true)
      cidr_blocks      = compact(split(",", lookup(ingress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(ingress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(ingress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(ingress.value, "security_groups", "")))
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", 0)
      to_port          = lookup(ingress.value, "to_port", 0)
      protocol         = lookup(ingress.value, "protocol", "-1")
    }
  }
  dynamic "egress" {
    for_each = var.default_security_group_egress
    content {
      self             = lookup(egress.value, "self", true)
      cidr_blocks      = compact(split(",", lookup(egress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(egress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(egress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(egress.value, "security_groups", "")))
      description      = lookup(egress.value, "description", null)
      from_port        = lookup(egress.value, "from_port", 0)
      to_port          = lookup(egress.value, "to_port", 0)
      protocol         = lookup(egress.value, "protocol", "-1")
    }
  }
  tags = merge(
    var.tags,
    {
      Name = format("%s-vpc-default-sg", lookup(var.tags, "Name", "default-name"))

    }
  )
}

resource "aws_default_route_table" "default" {
  count                  = var.enabled && var.aws_default_route_table ? 1 : 0
  default_route_table_id = join("", aws_vpc.default[*].default_route_table_id)
  dynamic "route" {
    for_each = var.default_route_table_routes
    content {
      # One of the following destinations must be provided
      cidr_block                 = route.value.cidr_block
      ipv6_cidr_block            = lookup(route.value, "ipv6_cidr_block", null)
      destination_prefix_list_id = lookup(route.value, "destination_prefix_list_id", null)
      # One of the following targets must be provided
      egress_only_gateway_id    = lookup(route.value, "egress_only_gateway_id", null)
      gateway_id                = lookup(route.value, "gateway_id", null)
      instance_id               = lookup(route.value, "instance_id", null)
      nat_gateway_id            = lookup(route.value, "nat_gateway_id", null)
      network_interface_id      = lookup(route.value, "network_interface_id", null)
      transit_gateway_id        = lookup(route.value, "transit_gateway_id", null)
      vpc_endpoint_id           = lookup(route.value, "vpc_endpoint_id", null)
      vpc_peering_connection_id = lookup(route.value, "vpc_peering_connection_id", null)
    }
  }
  tags = merge(
    var.tags,
    {
      Name = format("%s-default-rt", lookup(var.tags, "Name", "default-name"))
    }
  )
}

resource "aws_vpc_dhcp_options" "vpc_dhcp" {
  count                = var.enabled && var.enable_dhcp_options ? 1 : 0
  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type
  tags = merge(
    var.tags,
    {
      "Name" = format("%s-vpc-dhcp", var.tags)
    }
  )
}

resource "aws_vpc_dhcp_options_association" "this" {
  count           = var.enabled && var.enable_dhcp_options ? 1 : 0
  vpc_id          = join("", aws_vpc.default[*].id)
  dhcp_options_id = join("", aws_vpc_dhcp_options.vpc_dhcp[*].id)
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key" "kms" {
  count                   = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null ? 1 : 0
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.enable_key_rotation
}

resource "aws_kms_alias" "kms-alias" {
  count         = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null ? 1 : 0
  name          = format("alias/%s-flow-log-key", lookup(var.tags, "Name", "default-name"))
  target_key_id = join("", aws_kms_key.kms[*].key_id)
}

resource "aws_kms_key_policy" "this" {
  count  = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0
  key_id = join("", aws_kms_key.kms[*].id)
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "key-default-1",
    "Statement" : [{
      "Sid" : "Enable IAM User Permissions",
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action" : "kms:*",
      "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Principal" : { "Service" : "logs.${data.aws_region.current.name}.amazonaws.com" },
        "Action" : [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        "Resource" : "*"
      }
    ]
  })

}

resource "aws_s3_bucket" "this" {
  count  = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null && var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = var.flow_logs_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count  = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null && var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = join("", aws_s3_bucket.this[*].id)
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "this" {
  count      = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null && var.flow_log_destination_type == "s3" ? 1 : 0
  depends_on = [aws_s3_bucket_ownership_controls.this]
  bucket     = join("", aws_s3_bucket.this[*].id)
  acl        = "private"
}

resource "aws_s3_bucket_public_access_block" "this" {
  count                   = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null && var.flow_log_destination_type == "s3" ? 1 : 0
  bucket                  = join("", aws_s3_bucket.this[*].id)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null && var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = join("", aws_s3_bucket.this[*].id)
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = join("", aws_kms_key.kms[*].arn)
      sse_algorithm     = var.s3_sse_algorithm //"aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "block-http" {
  count  = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null && var.flow_log_destination_type == "s3" && var.block_http_traffic ? 1 : 0
  bucket = join("", aws_s3_bucket.this[*].id)

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "Blockhttp"
    Statement = [
      {
        "Sid" : "AllowSSLRequestsOnly",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          join("", aws_s3_bucket.this[*].arn),
          "${join("", aws_s3_bucket.this[*].arn)}/*",
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "flow_log" {
  count             = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0
  name              = format("%s-vpc-flow-log-cloudwatch_log_group", lookup(var.tags, "Name", "default"))
  retention_in_days = var.flow_log_cloudwatch_log_group_retention_in_days
  kms_key_id        = join("", aws_kms_key.kms[*].arn)
  tags              = var.tags
}

resource "aws_iam_role" "vpc_flow_log_cloudwatch" {
  count                = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null && var.flow_log_destination_type == "cloud-watch-logs" && var.create_flow_log_cloudwatch_iam_role ? 1 : 0
  name                 = format("%s-vpc-flow-log-role", lookup(var.tags, "Name", "default"))
  assume_role_policy   = join("", data.aws_iam_policy_document.flow_log_cloudwatch_assume_role[*].json)
  permissions_boundary = var.vpc_flow_log_permissions_boundary
  tags                 = var.tags
}

data "aws_iam_policy_document" "flow_log_cloudwatch_assume_role" {
  count = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null && var.flow_log_destination_type == "cloud-watch-logs" && var.create_flow_log_cloudwatch_iam_role ? 1 : 0
  statement {
    sid = "AWSVPCFlowLogsAssumeRole"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "vpc_flow_log_cloudwatch" {
  count      = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null && var.flow_log_destination_type == "cloud-watch-logs" && var.create_flow_log_cloudwatch_iam_role ? 1 : 0
  role       = join("", aws_iam_role.vpc_flow_log_cloudwatch[*].name)
  policy_arn = join("", aws_iam_policy.vpc_flow_log_cloudwatch[*].arn)
}

resource "aws_iam_policy" "vpc_flow_log_cloudwatch" {
  count  = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null && var.flow_log_destination_type == "cloud-watch-logs" && var.create_flow_log_cloudwatch_iam_role ? 1 : 0
  name   = format("%s-vpc-flow-log-to-cloudwatch", lookup(var.tags, "Name", "default-name"))
  policy = join("", data.aws_iam_policy_document.vpc_flow_log_cloudwatch[*].json)
  tags   = var.tags
}
#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "vpc_flow_log_cloudwatch" {
  count = var.enabled && var.enable_flow_log && var.flow_log_destination_arn == null && var.flow_log_destination_type == "cloud-watch-logs" && var.create_flow_log_cloudwatch_iam_role ? 1 : 0
  statement {
    sid    = "AWSVPCFlowLogsPushToCloudWatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["*"]
  }
}

resource "aws_flow_log" "vpc_flow_log" {
  count                    = var.enabled && var.enable_flow_log == true ? 1 : 0
  log_destination_type     = var.flow_log_destination_type
  log_destination          = var.flow_log_destination_arn == null ? (var.flow_log_destination_type == "s3" ? join("", aws_s3_bucket.this[*].arn) : join("", aws_cloudwatch_log_group.flow_log[*].arn)) : var.flow_log_destination_arn
  log_format               = var.flow_log_log_format
  iam_role_arn             = var.create_flow_log_cloudwatch_iam_role ? join("", aws_iam_role.vpc_flow_log_cloudwatch[*].arn) : var.flow_log_iam_role_arn
  traffic_type             = var.flow_log_traffic_type
  vpc_id                   = join("", aws_vpc.default[*].id)
  max_aggregation_interval = var.flow_log_max_aggregation_interval
  dynamic "destination_options" {
    for_each = var.flow_log_destination_type == "s3" ? [true] : []

    content {
      file_format                = var.flow_log_file_format
      hive_compatible_partitions = var.flow_log_hive_compatible_partitions
      per_hour_partition         = var.flow_log_per_hour_partition
    }
  }
  tags = var.tags
}


resource "aws_default_network_acl" "default" {
  count                  = var.enabled && var.aws_default_network_acl ? 1 : 0
  default_network_acl_id = join("", aws_vpc.default[*].default_network_acl_id)
  dynamic "ingress" {
    for_each = var.default_network_acl_ingress
    content {
      action          = ingress.value.action
      cidr_block      = lookup(ingress.value, "cidr_block", null)
      from_port       = ingress.value.from_port
      icmp_code       = lookup(ingress.value, "icmp_code", null)
      icmp_type       = lookup(ingress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(ingress.value, "ipv6_cidr_block", null)
      protocol        = ingress.value.protocol
      rule_no         = ingress.value.rule_no
      to_port         = ingress.value.to_port
    }
  }
  dynamic "egress" {
    for_each = var.default_network_acl_egress
    content {
      action          = egress.value.action
      cidr_block      = lookup(egress.value, "cidr_block", null)
      from_port       = egress.value.from_port
      icmp_code       = lookup(egress.value, "icmp_code", null)
      icmp_type       = lookup(egress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(egress.value, "ipv6_cidr_block", null)
      protocol        = egress.value.protocol
      rule_no         = egress.value.rule_no
      to_port         = egress.value.to_port
    }
  }
  tags = merge(
    var.tags,
    {
      Name = format("%s-nacl", lookup(var.tags, "Name", "default-name"))
    }
  )
}
