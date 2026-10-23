variable "services" {
  description = "Service names mapped to their permitted DNS SANs."

  type = map(list(string))

  default = {
    appgw = ["appgw.company.internal"]
  }
}

resource "tls_private_key" "server" {
  for_each  = var.services
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server" {
  for_each        = var.services
  private_key_pem = tls_private_key.server[each.key].private_key_pem

  subject {
    common_name  = each.value[0]
    organization = "Example Company"
  }

  dns_names = each.value
}

resource "tls_locally_signed_cert" "server" {
  for_each = var.services

  cert_request_pem   = tls_cert_request.server[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.intermediate.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.intermediate.cert_pem

  validity_period_hours = 2160 # 90 days

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

resource "local_file" "server_cert" {
  for_each = var.services

  filename = "${path.module}/cert/${each.key}.pem"
  content  = tls_locally_signed_cert.server[each.key].cert_pem

  file_permission = "0644"
}

resource "local_sensitive_file" "server_key" {
  for_each = var.services

  filename = "${path.module}/cert/${each.key}-key.pem"
  content  = tls_private_key.server[each.key].private_key_pem

  file_permission = "0600"
}

resource "local_file" "server_chain" {
  for_each = var.services

  filename = "${path.module}/cert/${each.key}-chain.pem"

  content = join("\n", [
    trimspace(tls_locally_signed_cert.server[each.key].cert_pem),
    trimspace(tls_locally_signed_cert.intermediate.cert_pem),
    ""
  ])

  file_permission = "0644"
}

## app gateway cert pfx

variable "pfx_password" {
  description = "Password protecting the Application Gateway PFX"
  type        = string
  sensitive   = true
  nullable    = false
  default     = "supersecret"
}

resource "terraform_data" "appgw_pfx" {
  triggers_replace = {
    certificate  = sha256(tls_locally_signed_cert.server["appgw"].cert_pem)
    private_key  = sha256(tls_private_key.server["appgw"].private_key_pem)
    intermediate = sha256(tls_locally_signed_cert.intermediate.cert_pem)
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -eu
      umask 077

      openssl pkcs12 -export \
        -out "${path.module}/cert/appgw.pfx" \
        -inkey "${path.module}/cert/appgw-key.pem" \
        -in "${path.module}/cert/appgw.pem" \
        -certfile "${path.module}/cert/intermediate-ca.pem" \
        -name "appgw" \
        -passout env:PFX_PASSWORD
    EOT

    environment = {
      PFX_PASSWORD = var.pfx_password
    }
  }

  depends_on = [
    local_file.server_cert,
    local_sensitive_file.server_key,
    local_file.server_chain,
  ]
}

data "local_file" "appgw_pfx" {
  filename   = "${path.module}/cert/appgw.pfx"
  depends_on = [terraform_data.appgw_pfx]
}
