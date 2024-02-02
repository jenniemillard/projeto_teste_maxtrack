provider "aws" {
  region                   = var.aws_region                                                 #Obtém o valor da variável var.aws_region, que deve conter o código da região desejada
  allowed_account_ids      = var.allowed_account_ids                                        #Obtém o valor da variável var.allowed_account_ids, que deve conter uma lista de IDs de conta AWS permitidas.
  shared_credentials_files = ["~/.aws/credentials"]                                         #Define uma lista com o caminho para o arquivo de credenciais compartilhadas da AWS, normalmente localizado em ~/.aws/credentials. Este arquivo contém informações de acesso, como a chave de acesso e a chave secreta
  shared_config_files      = ["~/.aws/config"]                                              #Define uma lista com o caminho para o arquivo de configuração compartilhado da AWS, normalmente localizado em ~/.aws/config. Este arquivo pode conter configurações adicionais, como perfis e configurações específicas do usuário.
  #  profile                  = "default"
}

provider "kubernetes" {                                                                     #interage com um cluster EKS
  host                   = module.eks.cluster_endpoint                                      #Especifica o endpoint do servidor Kubernetes.Obtém o valor do endpoint do cluster EKS do módulo EKS (module.eks.cluster_endpoint), que é onde o servidor Kubernetes está disponível.
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)      #Obtém o valor do certificado de autoridade do cluster do módulo EKS (module.eks.cluster_certificate_authority_data) e decodifica a representação base64 para um formato legível.

  # Windows
  config_path = "C:\\Users\\JenniferMillard\\.kube\\config"                                 #especifica o caminho para o arquivo de configuração Kubernetes no ambiente Windows. 
  # Linux
  #  config_path            = "/home/user/.kube/config"

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"                                    #Especificam a versão da API e o comando a ser executado para autenticação no cluster Kubernetes.
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]                  #Especifica os argumentos a serem passados ao comando aws para obter o token de autenticação do cluster EKS. Isso utiliza a CLI da AWS (aws eks get-token --cluster-name <cluster_name>).
  }
}

#data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}                                                     # utiliza um recurso de dados (data source) chamado aws_caller_identity para recuperar informações sobre a identidade que está fazendo a chamada ao AWS. 

module "load_balancer_controller" {                                                         #utiliza um módulo chamado load_balancer_controller, que é referenciado pelo caminho local ./aws_lb_controller
  source = "./aws_lb_controller"

  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url                     #Fornece a URL do emissor OIDC (OpenID Connect) do cluster EKS.
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn                           #Fornece o ARN (Amazon Resource Name) do provedor OIDC associado ao cluster EKS.
  cluster_name                     = module.eks.cluster_name                                #Fornece o nome do cluster EKS.

  enabled    = true                                                                         #Indica se o módulo está habilitado 
  depends_on = [null_resource.update-kubeconfig]                                            #Indica que este módulo depende de um recurso chamado null_resource.update-kubeconfig. Isso implica que há algum recurso adicional chamado null_resource.update-kubeconfig que deve ser criado ou atualizado antes deste módulo.
}


resource "null_resource" "update-kubeconfig" {                                              # Prove um recurso nulo para atualizar o kubeconfig com as informacoes do cluster em questao

  triggers = {
    value = module.eks.cluster_name                                                         #Define um gatilho para este recurso nulo. O valor do gatilho é o nome do cluster EKS (module.eks.cluster_name).  garante que o comando de atualização do kubeconfig seja executado sempre que o nome do cluster EKS for alterado.
  }

  depends_on = [module.eks]                                                                 #Especifica que este recurso nulo depende do módulo EKS (module.eks).Garante que o comando de atualização do kubeconfig seja executado somente após a criação ou atualização bem-sucedida do módulo EKS. 

  provisioner "local-exec" {
    command     = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}" #Define o comando local a ser executado. Utiliza a CLI da AWS para atualizar o kubeconfig.
    interpreter = ["PowerShell", "-Command"]                                                #Especifica o interpretador a ser usado para executar o comando local. Neste caso, está usando PowerShell.
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
#criar um cluster Amazon Elastic Kubernetes Service (EKS)
module "eks" {
  source                          = "terraform-aws-modules/eks/aws"                            #Especifica a origem do módulo, neste caso, o repositório Terraform Registry
  version                         = "~> 19.0"                                                  #Especifica a versão do módulo que deve ser usada.
  cluster_name                    = var.cluster_name                                           #Configura o nome do cluster EKS, utilizando o valor da variável cluster_name fornecida externamente.
  cluster_version                 = var.cluster_version                                        #Configura a versão do Kubernetes para o cluster EKS, utilizando o valor da variável cluster_version 
  vpc_id                          = aws_vpc.this.id                                            #Especifica o ID da VPC na qual o cluster EKS será criado. O valor é extraído da saída vpc_id do bloco AWS VPC chamado this.    
  subnet_ids                      = [for subnet_name, subnet in aws_subnet.this : subnet.id]   #Lista de IDs de subnets onde o cluster EKS será lançado.
  cluster_endpoint_public_access  = true                                                       #Habilita o acesso público ao endpoint do cluster EKS.
  cluster_endpoint_private_access = true                                                       #Habilita o acesso privado ao endpoint do cluster EKS.
  cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"] #Declarando qual tipo de log estão habilitados para o cluster

  cluster_addons = {                                                                           #Configura addons específicos do cluster EKS, como coredns, kube-proxy, vpc-cni e aws-ebs-csi-driver.
    coredns = {                                                                                #Define como lidar com conflitos no momento da criação do addon. Se houver conflitos durante a criação, os valores existentes serão sobrescritos.
      most_recent = true
    }
    kube-proxy = {                                                                             #Gerencia o redirecionamento de tráfego de rede para os pods. Ele mantém as regras de IPTables para direcionar pacotes de entrada para os pods corretos, facilitando a comunicação entre os diferentes componentes do cluster.
      most_recent = true
    }
    vpc-cni = {                                                                                #permite que os pods dentro do cluster EKS se comuniquem através de IPs da VPC (Virtual Private Cloud) da AWS.            
      most_recent = true
    }

    aws-ebs-csi-driver = {                                                                     #integra o EBS ao cluster Kubernetes gerenciado pelo EKS. Ele permite que os usuários provisionem volumes EBS e os montem em pods Kubernetes de maneira simples e integrada.
      most_recent = true
    }
  }

  manage_aws_auth_configmap = true                                                             #indica que o Terraform deve gerenciar automaticamente o ConfigMap chamado aws-auth 

  eks_managed_node_groups = {                                                                  #grupo de nós gerenciados
    node-group = {
      name           = "workers-teste"                                                         #Nome do grupo de nós
      instance_types = ["${var.tipomaquina}"]                                                  #Tipo de instância
      min_size       = 1                                                                       #Número mínimo de instâncias
      max_size       = 2                                                                       #Número máximo de instâncias
      desired_size   = 2                                                                       #Número desejado de instâncias

      timeouts = {                                                                             #Limite de tempo para criação e exclusão do node group
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

module "kms" {                                                                                  #criar uma chave do AWS Key Management Service (KMS). 
  source      = "terraform-aws-modules/kms/aws"                                                 #Especifica a origem do módulo, neste caso, o repositório Terraform Registry terraform-aws-modules/kms/aws.
  description = "Chaves KMS para o cluster ${var.cluster_name}"                                 
  # Policy
  enable_default_policy = true                                                                  #Habilita a criação de uma política padrão para a chave.
  key_owners            = [data.aws_caller_identity.current.arn]                                #Lista de entidades IAM que são os proprietários da chave.

}

module "key_pair" {                                                                             # gera par de chaves para acesso aos nodes EC2
  source = "terraform-aws-modules/key-pair/aws"                                                 #Especifica a origem do módulo, neste caso, o repositório Terraform Registry terraform-aws-modules/key-pair/aws.

  key_name           = "aws-nodes-teste"                                                        #Especifica o nome da chave. 
  create_private_key = true                                                                     #Indica se a chave privada deve ser criada. Se configurado como true, o módulo gera tanto a chave privada quanto a pública. Se configurado como false, apenas a chave pública será gerada.
}
