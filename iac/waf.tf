# =============================================================================
# waf.tf — AWS WAFv2 web ACL attached to the ALB (perimeter filtering)
#   - AWS managed Common Rule Set (broad OWASP coverage)
#   - AWS managed SQL injection rule set
#   Toggle with var.enable_waf = false if the sandbox blocks WAFv2.
#   Useful for Part E: send a simple SQLi string and confirm WAF blocks it.
# =============================================================================

resource "aws_wafv2_web_acl" "alb" {
  count       = var.enable_waf ? 1 : 0
  name        = "${var.project_name}-waf"
  scope       = "REGIONAL"
  description = "WAF for the application ALB"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSCommonRules"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSCommonRules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSSQLiRules"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSSQLiRules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "alb" {
  count        = var.enable_waf ? 1 : 0
  resource_arn = aws_lb.app.arn
  web_acl_arn  = aws_wafv2_web_acl.alb[0].arn
}
