resource "tls_private_key" "root" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "root" {
  private_key_pem = tls_private_key.root.private_key_pem

  subject {
    common_name  = "Example Company Root CA"
    organization = "Example Company"
  }

  validity_period_hours = 8760 # 1 year

  is_ca_certificate = true
  max_path_length   = 1

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

resource "local_file" "root_cert" {
  filename        = "${path.module}/cert/root-ca.pem"
  content         = tls_self_signed_cert.root.cert_pem
  file_permission = "0644"
}

resource "local_sensitive_file" "root_key" {
  filename             = "${path.module}/cert/root-ca-key.pem"
  content              = tls_private_key.root.private_key_pem
  file_permission      = "0600"
}

output "root_certificate_path" {
  value = local_file.root_cert.filename
}
