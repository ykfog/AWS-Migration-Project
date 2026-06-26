# =============================================================================
# tls.tf — Self-signed TLS certificate imported into ACM for the ALB HTTPS:443
#   listener (encryption in transit). Salvaged from the teammate's original
#   security.tf and gated behind var.enable_https.
#
#   The tls_* resources are LOCAL (no AWS call) and always succeed. The ACM
#   import (aws_acm_certificate) calls acm:ImportCertificate, which may be
#   blocked by the sandbox SCP — if apply errors with AccessDenied, leave
#   enable_https = false and document HTTPS as IaC-only.
#
#   A public ACM-validated cert is not possible here (no validatable domain),
#   so a self-signed cert is used; browsers will warn, which is expected.
# =============================================================================

resource "tls_private_key" "app_key" {
  count     = var.enable_https ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "app_cert" {
  count           = var.enable_https ? 1 : 0
  private_key_pem = tls_private_key.app_key[0].private_key_pem

  subject {
    common_name  = "mmu-secure-migration.local"
    organization = "MMU Cloud Security Group"
  }

  validity_period_hours = 720 # 30 days
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "imported_cert" {
  count            = var.enable_https ? 1 : 0
  private_key      = tls_private_key.app_key[0].private_key_pem
  certificate_body = tls_self_signed_cert.app_cert[0].cert_pem

  tags = { Name = "${var.project_name}-self-signed-cert" }
}
