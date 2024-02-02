output "cluster_endpoint" {
  description = "Endpoint para EKS control plane"
  value       = module.eks.cluster_endpoint                                     #Obtém o valor do endpoint do módulo EKS que é um endpoint para se comunicar com o control plane do EKS.
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id                            #Obtém o valor do ID do grupo de segurança do módulo EKS 
}


output "region" {
  description = "AWS region"
  value       = var.aws_region                                                  #Obtém o valor da variável var.aws_region, que especifica a região da AWS na qual a infraestrutura está sendo provisionada.                                         
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name                                         #Obtém o valor do nome do cluster do módulo EKS (module.eks.cluster_name), que é o nome atribuído ao cluster Kubernetes.
}


########## Key Pairs ######################

output "key_pair_id" {
  description = "The key pair ID"
  value       = module.key_pair.key_pair_id
}

output "key_pair_arn" {
  description = "The key pair ARN"
  value       = module.key_pair.key_pair_arn
}

output "key_pair_name" {
  description = "The key pair name"
  value       = module.key_pair.key_pair_name
}

output "key_pair_fingerprint" {
  description = "The MD5 public key fingerprint as specified in section 4 of RFC 4716"
  value       = module.key_pair.key_pair_fingerprint
}

output "private_key_id" {
  description = "Unique identifier for this resource: hexadecimal representation of the SHA1 checksum of the resource"
  value       = module.key_pair.private_key_id
}

output "private_key_openssh" {
  description = "Private key data in OpenSSH PEM (RFC 4716) format"
  value       = module.key_pair.private_key_openssh
  sensitive   = true
}

output "private_key_pem" {
  description = "Private key data in PEM (RFC 1421) format"
  value       = module.key_pair.private_key_pem
  sensitive   = true
}

output "public_key_fingerprint_md5" {
  description = "The fingerprint of the public key data in OpenSSH MD5 hash format, e.g. `aa:bb:cc:....` Only available if the selected private key format is compatible, similarly to `public_key_openssh` and the ECDSA P224 limitations"
  value       = module.key_pair.public_key_fingerprint_md5
}

output "public_key_fingerprint_sha256" {
  description = "The fingerprint of the public key data in OpenSSH SHA256 hash format, e.g. `SHA256:....` Only available if the selected private key format is compatible, similarly to `public_key_openssh` and the ECDSA P224 limitations"
  value       = module.key_pair.public_key_fingerprint_sha256
}

output "public_key_openssh" {
  description = "The public key data in \"Authorized Keys\" format. This is populated only if the configured private key is supported: this includes all `RSA` and `ED25519` keys"
  value       = module.key_pair.public_key_openssh
}

output "public_key_pem" {
  description = "Public key data in PEM (RFC 1421) format"
  value       = module.key_pair.public_key_pem
}

##########################################################################