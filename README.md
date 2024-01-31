README

Para fazer o deploy do projeto você pode executar os comandos listados abaixo. Lembre-se de configurar as credenciais para que o Terraform possa se comunicar com a sua conta na AWS.

O primeiro passo é iniciar o seu projeto Terraform executando o comando abaixo.

```
$ terraform init
```

Depois disso, caso você queria ver apenas um plano do que será feito na sua conta, você pode executar o seguinte comando:

```
$ terraform plan
```

Para criar os recursos na sua conta, você pode executar o comando abaixo e confirmar o plano apresentado.

```
$ terraform apply
```

Se você não quiser manter os recursos na sua conta, você pode destruir toda a infraestrutura com o seguinte comando:

```
$ terraform destroy
```

## 

Desenvolvido por Jennifer Millard, para realização de Teste Prático.
