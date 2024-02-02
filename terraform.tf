terraform {

  required_providers {
#Fornece suporte para interagir com a API da Amazon Web Services (AWS)
    aws = {
      source  = "hashicorp/aws"                     #Indica a origem do provedor. 
      version = "~> 5.0"                            #Define a versão mínima do provedor AWS que deve ser usada.
    }

#Oferece recursos para gerar números aleatórios e strings. 
    random = {
      source  = "hashicorp/random"                  #Indica a origem do provedor Random.
      version = "~> 3.5.1"                          #Define a versão mínima do provedor Random.
    }

#Permitir a criação e gestão de recursos relacionados à camada de segurança de transporte (TLS). 
    tls = {
      source  = "hashicorp/tls"                     #Indica a origem do provedor TLS.
      version = "~> 4.0.4"                          #Define a versão mínima do provedor TLS.
    }

#Gerenciar configurações de inicialização (cloud-init) em instâncias. 
    cloudinit = {
      source  = "hashicorp/cloudinit"               #Indica a origem do provedor Cloudinit.
      version = "~> 2.3.2"                          #Define a versão mínima do provedor Cloudinit.
    }
  }
}