provider "aws" {
  region                   = var.aws_region
  allowed_account_ids      = var.allowed_account_ids
  shared_credentials_files = ["~/.aws/credentials"]
  shared_config_files      = ["~/.aws/config"]
  #  profile                  = "default"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  # Windows
  config_path = "C:\\Users\\JenniferMillard\\.kube\\config"
  #  # Linux
  #  config_path            = "/home/user/.kube/config"

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

#data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

module "load_balancer_controller" {
  source = "./aws_lb_controller"

  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  cluster_name                     = module.eks.cluster_name

  enabled    = true
  depends_on = [null_resource.update-kubeconfig]
}


resource "null_resource" "update-kubeconfig" { # Prove um recurso nulo para atualizar o kubeconfig com as informacoes do cluster em questao

  triggers = {
    value = module.eks.cluster_name
  }

  depends_on = [module.eks]

  provisioner "local-exec" {
    command     = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
    interpreter = ["PowerShell", "-Command"]
  }
}

#module "vpc" {
#  source               = "terraform-aws-modules/vpc/aws"
#  name                 = "vpc-teste"
#  cidr                 = "10.0.0.0/16"
#  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
#  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
#  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
#  create_igw           = true
#  enable_nat_gateway   = true
#  single_nat_gateway   = true
#  enable_dns_hostnames = true
#}

module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "~> 19.0"
  cluster_name                    = var.cluster_name    #Configura o nome do cluster EKS, utilizando o valor da variável cluster_name fornecida externamente.
  cluster_version                 = var.cluster_version #Configura a versão do Kubernetes para o cluster EKS, utilizando o valor da variável cluster_version 
  vpc_id                          = aws_vpc.this.id     #Especifica o ID da VPC na qual o cluster EKS será criado. O valor é extraído da saída vpc_id do bloco AWS VPC chamado this.    
  subnet_ids                      = [for subnet_name, subnet in aws_subnet.this : subnet.id]
  cluster_endpoint_public_access  = true                                                                #Habilita o acesso público ao endpoint do cluster EKS.
  cluster_endpoint_private_access = true                                                                #
  cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"] #Declarando qual tipo de log estão habilitados para o cluster

  cluster_addons = {
    coredns = { #Define como lidar com conflitos no momento da criação do addon. Se houver conflitos durante a criação, os valores existentes serão sobrescritos.
      most_recent = true
    }
    kube-proxy = { #Gerencia o redirecionamento de tráfego de rede para os pods. Ele mantém as regras de IPTables para direcionar pacotes de entrada para os pods corretos, facilitando a comunicação entre os diferentes componentes do cluster.
      most_recent = true
    }
    vpc-cni = { #permite que os pods dentro do cluster EKS se comuniquem através de IPs da VPC (Virtual Private Cloud) da AWS.            
      most_recent = true
    }

    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  manage_aws_auth_configmap = true #indica que o Terraform deve gerenciar automaticamente o ConfigMap chamado aws-auth 

  eks_managed_node_groups = { #grupo de nós gerenciados
    node-group = {
      name           = "workers-teste"        #Nome do grupo de nós
      instance_types = ["${var.tipomaquina}"] #Tipo de instância
      min_size       = 1                      #Número mínimo de instâncias
      max_size       = 2                      #Número máximo de instâncias
      desired_size   = 2                      #Número desejado de instâncias

      timeouts = { #Limite de tempo para criação e exclusão do node group
        create = "15m"
        delete = "15m"

      }
      additional_policies = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]
    }
  }

  #  # Regras IAM para o cluster
  #  create_iam_role = false
  #  iam_role_arn    = aws_iam_role.teste-eks-role.arn

  #  aws_auth_node_iam_role_arns_non_windows = [
  #    "arn:aws:iam::aws:policy/service-role/AmazonEKSWorkerNodePolicy",
  #    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
  #  ]

}

module "kms" {
  source      = "terraform-aws-modules/kms/aws"
  description = "Chaves KMS para o cluster ${var.cluster_name}"
  # Policy
  enable_default_policy = true                                   #Habilita a criação de uma política padrão para a chave.
  key_owners            = [data.aws_caller_identity.current.arn] #Lista de entidades IAM que são os proprietários da chave.

}

module "key_pair" { # gera par de chaves para acesso aos nodes EC2
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "aws-nodes-teste"
  create_private_key = true
}
