
resource "tls_private_key" "intermediate" {
  algorithm = "RSA"
  rsa_bits  = 3072
}

resource "tls_cert_request" "intermediate" {
  private_key_pem = tls_private_key.intermediate.private_key_pem

  subject {
    common_name  = "Example Company Issuing CA"
    organization = "Example Company"
  }
}

resource "local_file" "intermediate_csr" {
  filename        = "${path.module}/cert/intermediate-ca.csr"
  content         = tls_cert_request.intermediate.cert_request_pem
  file_permission = "0644"
}

resource "local_sensitive_file" "intermediate_key" {
  filename        = "${path.module}/cert/intermediate-ca-key.pem"
  content         = tls_private_key.intermediate.private_key_pem
  file_permission = "0600"
}

output "csr_path" {
  value = local_file.intermediate_csr.filename
}

# generate the intermediate ca cert

resource "tls_locally_signed_cert" "intermediate" {
  cert_request_pem   = local_file.intermediate_csr.content
  ca_private_key_pem = tls_private_key.root.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root.cert_pem

  validity_period_hours = 26280
  is_ca_certificate     = true
  max_path_length       = 0

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

resource "local_file" "intermediate_cert" {
  count = length(tls_locally_signed_cert.intermediate)

  filename = "${path.module}/cert/intermediate-ca.pem"
  content  = tls_locally_signed_cert.intermediate.cert_pem

  file_permission = "0644"
}

resource "terraform_data" "intermediate_chain" {
  triggers_replace = {
    intermediate_certificate = sha256(tls_locally_signed_cert.intermediate.cert_pem)
    intermediate_private_key = sha256(tls_private_key.intermediate.private_key_pem)
    root_certificate         = sha256(tls_self_signed_cert.root.cert_pem)
  }

  provisioner "local-exec" {
    command = <<-EOT
        cat ${path.module}/cert/intermediate-ca.pem ${path.module}/cert/root-ca.pem > ${path.module}/cert/cacerts.pem
    EOT
  }

  depends_on = [
    local_file.root_cert,
    local_file.intermediate_cert
  ]
}

data "local_file" "intermediate_chain" {
  filename   = "${path.module}/cert/cacerts.pem"
  depends_on = [terraform_data.intermediate_chain]
}