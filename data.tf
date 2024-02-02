#obter informações sobre as zonas de disponibilidade (Availability Zones) disponíveis na região AWS especificada.
data "aws_availability_zones" "available" {                                             #Especifica o tipo de recurso de dados a ser utilizado, que neste caso é para obter informações sobre as zonas de disponibilidade AWS. available": É um alias que será utilizado para referenciar os resultados desse recurso de dados.
  state = "available"                                                                   #Define o estado das zonas de disponibilidade a serem recuperadas. 
}
