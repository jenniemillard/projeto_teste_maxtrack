locals {
  private_subnets = sort([for subnet in var.vpc_configuration.subnets : subnet.name if subnet.public == false])     #Cria uma lista das sub-redes (subnets) privadas
  public_subnets  = sort([for subnet in var.vpc_configuration.subnets : subnet.name if subnet.public == true])      #Cria uma lista das sub-redes que são públicas 
  azs             = sort(slice(data.aws_availability_zones.available.zone_ids, 0, length(local.private_subnets)))   #Cria uma lista de IDs de zonas de disponibilidade (Availability Zones) associadas às sub-redes privadas (local.private_subnets).A função slice é usada para limitar o número de zonas de disponibilidade ao mesmo número de sub-redes privadas.
  subnet_pairs    = zipmap(local.private_subnets, local.public_subnets)                                             #Cria um mapa que associa cada sub-rede privada à sua correspondente sub-rede pública. Usa a função zipmap para combinar local.private_subnets e local.public_subnets em um mapa.

  az_pairs = merge(                                                                                                 #Cria um mapa que associa cada sub-rede (seja privada ou pública) à sua respectiva zona de disponibilidade (az).Usa a função merge e zipmap para combinar informações de zonas de disponibilidade com as sub-redes privadas e públicas.
    zipmap(local.private_subnets, local.azs),
    zipmap(local.public_subnets, local.azs)
  )
}
