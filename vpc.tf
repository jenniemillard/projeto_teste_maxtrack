resource "aws_vpc" "this" {                                                           #um recurso VPC na AWS com o nome "this".
  cidr_block           = var.vpc_configuration.cidr_block                             #Define o bloco CIDR (Classless Inter-Domain Routing) para a VPC. O valor é obtido da variável var.vpc_configuration.cidr_block.
  enable_dns_hostnames = true                                                         #Configuração para habilitar ou desabilitar a resolução de nomes de host DNS para instâncias na VPC. 
  enable_dns_support   = true                                                         #Configuração para habilitar ou desabilitar o suporte a DNS na VPC. 

  tags = {                                                                            #metadados atribuídos ao recurso para facilitar a identificação e gerenciamento.
    Name                                        = "vpc_teste"                         #Nome da VPC
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"                            #Indica que a VPC faz parte de um cluster Kubernetes com o nome fornecido pela variável var.cluster_name
    "kubernetes.io/role/elb"                    = "1"                                 #Indica o papel da VPC em relação aos balanceadores de carga   
  }
}

#define um recurso Internet Gateway na AWS. Permite a comunicação entre recursos na VPC e a Internet.
resource "aws_internet_gateway" "this" {                                              #define um recurso Internet Gateway na AWS. This é o  identificador único para este recurso dentro do escopo do módulo ou configuração. 
  vpc_id = aws_vpc.this.id                                                            # ID da VPC à qual o Internet Gateway será associado. O valor utilizado aqui é aws_vpc.this.id, referenciando a ID da VPC definida anteriormente com o nome "this".
}

resource "aws_subnet" "this" {                                                         #
  for_each = { for subnet in var.vpc_configuration.subnets : subnet.name => subnet }   # iterar sobre as subnets definidas na variável var.vpc_configuration.subnets. A estrutura da iteração cria um mapa associando o nome da subnet (subnet.name) ao objeto de configuração da subnet (subnet)

  availability_zone_id    = local.az_pairs[each.key]                                   #Especifica a zona de disponibilidade (Availability Zone) para a subnet. O valor é obtido da variável local local.az_pairs usando a chave correspondente à subnet atual (local.az_pairs[each.key]).
  vpc_id                  = aws_vpc.this.id                                            #Define a ID da VPC à qual a subnet pertence. A ID é obtida referenciando o recurso VPC definido anteriormente (aws_vpc.this.id).
  cidr_block              = each.value.cidr_block                                      #Define o bloco CIDR da subnet. O valor é obtido da configuração da subnet atual (each.value.cidr_block).
  map_public_ip_on_launch = each.value.public                                          #Indica se os recursos lançados nesta subnet terão ou não IPs públicos automaticamente associados. O valor é obtido da configuração da subnet atual (each.value.public).

  tags = {
    Name                                        = each.key                             #chave da iteração 
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"                             #Indica que a subnet faz parte de um cluster Kubernetes
    "kubernetes.io/role/internal-elb"           = "1"                                  #Indica o papel da subnet em relação aos balanceadores de carga internos, com o valor "1".
  }
}

resource "aws_nat_gateway" "this" {                                                    #
  for_each = toset(local.private_subnets)                                              #Este bloco utiliza a função for_each para iterar sobre um conjunto (set) de subnets privadas definido na variável local local.private_subnets. Cada valor em local.private_subnets representa uma subnet privada. 

  allocation_id = aws_eip.nat_gateway[each.value].id                                   #Especifica a ID de alocação do Elastic IP (EIP) associado ao NAT Gateway. A ID é obtida referenciando o recurso aws_eip com o índice correspondente à subnet privada atual (aws_eip.nat_gateway[each.value].id).   
  subnet_id     = aws_subnet.this[local.subnet_pairs[each.value]].id                   #Especifica a ID da subnet à qual o NAT Gateway está associado. A ID é obtida referenciando o recurso aws_subnet com o índice correspondente à subnet privada atual (aws_subnet.this[local.subnet_pairs[each.value]].id).
}

resource "aws_eip" "nat_gateway" {                                                     #cria recursos do tipo aws_eip
  for_each = toset(local.private_subnets)                                              #Este bloco utiliza a função for_each para iterar sobre um conjunto (set) de subnets privadas definido na variável local local.private_subnets. Cada valor em local.private_subnets representa uma subnet privada.
  domain   = "vpc"                                                                     #Define o domínio do Elastic IP como "vpc", indicando que o EIP está associado a uma VPC. 

  depends_on = [aws_internet_gateway.this]                                             #indica que a criação deste recurso depende da conclusão da criação do Internet Gateway. 
}

resource "aws_route_table" "public" {                                                   #cria um recurso do tipo aws_route_table para gerenciar as rotas em uma VPC.
  vpc_id = aws_vpc.this.id                                                              #Especifica a ID da VPC à qual a tabela de roteamento pertence. O valor é obtido referenciando o recurso VPC definido anteriormente (aws_vpc.this.id).
}

#Criação de rota em tabela de roteamento
resource "aws_route" "internet_gateway" {                                               #cria um recurso do tipo aws_route
  destination_cidr_block = "0.0.0.0/0"                                                  #Especifica o bloco CIDR de destino para a rota. Neste caso, está configurado como "0.0.0.0/0", o que indica que é uma rota padrão, ou seja, para qualquer destino.
  route_table_id         = aws_route_table.public.id                                    #Especifica a ID da tabela de roteamento à qual esta rota pertence. O valor é obtido referenciando o recurso de tabela de roteamento definido anteriormente (aws_route_table.public.id).
  gateway_id             = aws_internet_gateway.this.id                                 #Especifica a ID do Internet Gateway ao qual a rota direciona o tráfego. O valor é obtido referenciando o recurso de Internet Gateway definido anteriormente (aws_internet_gateway.this.id).
}

#criando associações entre subnets públicas e uma tabela de roteamento pública.
resource "aws_route_table_association" "public" {                                       #cria um recurso do tipo aws_route_table_association
  for_each       = toset(local.public_subnets)                                          #utiliza a função for_each para iterar sobre um conjunto (set) de subnets públicas definido na variável local local.public_subnets. Cada valor em local.public_subnets representa uma subnet pública.
  subnet_id      = aws_subnet.this[each.value].id                                       #Especifica a ID da subnet à qual a tabela de roteamento será associada. O valor é obtido referenciando o recurso aws_subnet com o índice correspondente à subnet pública atual (aws_subnet.this[each.value].id).
  route_table_id = aws_route_table.public.id                                            #Especifica a ID da tabela de roteamento que será associada à subnet. O valor é obtido referenciando o recurso aws_route_table definido anteriormente (aws_route_table.public.id).
}

#criando uma tabela de roteamento (aws_route_table) para subnets privadas.
resource "aws_route_table" "private" {                                                  #cria um recurso do tipo aws_route_table para gerenciar as rotas em uma VPC para subnets privadas.
  for_each = toset(local.private_subnets)                                               #utiliza a função for_each para iterar sobre um conjunto (set) de subnets privadas definido na variável local local.private_subnets. Cada valor em local.private_subnets representa uma subnet privada.
  vpc_id   = aws_vpc.this.id                                                            #Especifica a ID da VPC à qual a tabela de roteamento pertence. O valor é obtido referenciando o recurso VPC definido anteriormente (aws_vpc.this.id).
}

#criando rotas nas tabelas de roteamento associadas a subnets privadas. 
resource "aws_route" "nat_gateway" {                                                    #cria um recurso do tipo aws_route para subnets privadas associadas a NAT Gateways.
  for_each = toset(local.private_subnets)                                               #utiliza a função for_each para iterar sobre um conjunto (set) de subnets privadas definido na variável local local.private_subnets. Cada valor em local.private_subnets representa uma subnet privada.

  destination_cidr_block = "0.0.0.0/0"                                                  #Especifica o bloco CIDR de destino para a rota. Neste caso, está configurado como "0.0.0.0/0", indicando uma rota padrão para qualquer destino (a Internet).
  route_table_id         = aws_route_table.private[each.value].id                       #Especifica a ID da tabela de roteamento à qual esta rota pertence. O valor é obtido referenciando o recurso aws_route_table.private[each.value].id, que corresponde à tabela de roteamento privada associada à subnet privada atual.
  nat_gateway_id         = aws_nat_gateway.this[each.value].id                          #Especifica a ID do NAT Gateway ao qual a rota direciona o tráfego. 
}

#criando associações entre subnets privadas e tabelas de roteamento privadas.
resource "aws_route_table_association" "private" {                                      #cria associações entre subnets privadas e tabelas de roteamento privadas. 
  for_each       = toset(local.private_subnets)                                         #utiliza a função for_each para iterar sobre um conjunto (set) de subnets privadas definido na variável local local.private_subnets. Cada valor em local.private_subnets representa uma subnet privada.
  subnet_id      = aws_subnet.this[each.value].id                                       #Especifica a ID da subnet à qual a tabela de roteamento será associada. O valor é obtido referenciando o recurso aws_subnet com o índice correspondente à subnet privada atual (aws_subnet.this[each.value].id).
  route_table_id = aws_route_table.private[each.value].id                               #Especifica a ID da tabela de roteamento que será associada à subnet. O valor é obtido referenciando o recurso aws_route_table.private[each.value].id, que corresponde à tabela de roteamento privada associada à subnet privada atual.
}
