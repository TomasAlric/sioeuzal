# Guia de Uso do Projeto

Este projeto consiste em três módulos principais: frontend estático, backend em container e um cronjob serverless.

## Estrutura do Projeto

```
sioeuzal/
├── 01-frontend/        # Frontend estático (S3 + CloudFront)
├── 02-backend/         # Backend containerizado (ECS Fargate)
└── 03-cronjob/        # Cronjob serverless (Lambda + EventBridge)
```

## Pré-requisitos

- AWS CLI configurado
- Terraform >= 1.9.8
- Docker (para o backend)
- Python 3.12 (para o cronjob)
- Conta AWS com permissões adequadas

## Configuração Inicial

1. **Clone o repositório**
```bash
git clone <repository-url>
cd sioeuzal
```

2. **Configure as credenciais AWS**
```bash
aws configure
```

## Implantação

### Forma Manual

#### 1. Frontend (01-frontend)

```bash
cd 01-frontend/infra
terraform init
terraform plan -var-file=inventories/dev/terraform.tfvars
terraform apply -var-file=inventories/dev/terraform.tfvars

# Upload dos arquivos estáticos
BUCKET_ID=$(terraform output -raw bucket_name)
aws s3 sync ../app/src/ s3://${BUCKET_ID}/ --delete

# Invalidar cache do CloudFront
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths "/*"
```

#### 2. Backend (02-backend)

1. **Build e Push da Imagem Docker**
```bash
cd 02-backend/app
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build e tag da imagem
docker build -t backend-app .
docker tag backend-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/sioeuzal-dev:latest

# Push da imagem
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/sioeuzal-dev:latest

Acessar a tarefa do ECS pelo IP público para validar
```

2. **Deploy da Infraestrutura**
```bash
cd ../infra
terraform init
terraform plan -var-file=inventories/dev/terraform.tfvars
terraform apply -var-file=inventories/dev/terraform.tfvars
```

#### 3. Cronjob (03-cronjob)

```bash
cd 03-cronjob/infra
terraform init
terraform plan -var-file=inventories/dev/terraform.tfvars
terraform apply -var-file=inventories/dev/terraform.tfvars
```

### Forma Automatizada (CI/CD)

O projeto utiliza GitHub Actions para CI/CD. Os workflows estão em `.github/workflows/`.

#### Configuração do GitHub Actions

1. **Configure as seguintes variáveis no GitHub**:
   - `AWS_REGION`: Região AWS (ex: us-east-1)
   - `STATEFILE_BUCKET_NAME_TF_DEV`: Nome do bucket para Terraform state
   - `DYNAMODB_TABLE_TF`: Nome da tabela DynamoDB para state locking

2. **Configure os seguintes secrets no GitHub**:
   - `AWS_ASSUME_ROLE_ARN_DEV`: ARN da role para assumir na AWS
   - `AWS_ACCOUNT_ID`: ID da conta AWS

3. **Prepare o arquivo destroy_config.json na raiz**:
```json
{
  "dev": false
}
```

## Acionamento do Pipeline com Autenticação OIDC

### Passos para configurar o acesso AWS via GitHub Actions OIDC
1. Pré requisitos:
   - Ter uma organization no Github



1. **Criar um bucket S3 na AWS para ser o Statefile File**  
   - Anote o nome do bucket para usar no GitHub.

2. **Criar o Provedor OIDC no IAM**  
   - No console AWS, vá em **IAM > Provedores de identidade > Adicionar provedor**.  
   - Em tipo de provedor, selecione **OpenID Connect**.  
   - Informe a URL: `https://token.actions.githubusercontent.com`.  
   - Defina o **Público** como `sts.amazonaws.com`.  
   - Finalize para criar o provedor.

3. **Criar a Role IAM para o GitHub Actions**  
   - Crie uma role com tipo de entidade confiável **Web Identity**.  
   - Selecione o provedor OIDC criado.  
   - Defina o Audience como `sts.amazonaws.com`.  
   - Configure a trust policy para permitir somente seu repositório e branch, por exemplo:

    ```json
      {
      "Version":"2012-10-17",
      "Statement":[
         {
            "Effect":"Allow",
            "Action":"sts:AssumeRoleWithWebIdentity",
            "Principal":{
               "Federated":"arn:aws:iam::<ACCOUNT-ID>:oidc-provider/token.actions.githubusercontent.com"
            },
            "Condition":{
               "StringEquals":{
                  "token.actions.githubusercontent.com:aud":[
                     "sts.amazonaws.com"
                  ]
               },
               "StringLike":{
                  "token.actions.githubusercontent.com:sub":[
                     "repo:<ORG>/*"
                  ]
               }
            }
         }
      ]
   }
    ```

   - Dê um nome a role ex -> role-pipeline-gh-actions

4. **Adicionar as permissões necessárias na Role**  

   Para facilitar e garantir todas as permissões necessárias no pipeline, considere anexar as seguintes políticas gerenciadas AWS com acesso completo (**FullAccess**):

   | Serviço / Recurso                   | Políticas Gerenciadas AWS FullAccess                                |
   |-----------------------------------|-----------------------------------------------------------------------|
   | **S3**                            | `AmazonS3FullAccess`                                                  |
   | **CloudWatch Logs**               | `CloudWatchLogsFullAccess`                                            |
   | **IAM** (para roles e trust)      | `IAMFullAccess`                                                       |
   | **Lambda**                        | `AWSLambda_FullAccess`                                                |
   | **EventBridge**                   | `AmazonEventBridgeFullAccess`                                         |
   | **ECS / ECR** (se usar container) | `AmazonECS_FullAccess`, `AmazonEC2ContainerRegistryFullAccess`        |
   | **CloudFront**                    | `CloudFrontFullAccess`                                                |

   > ⚠️ **Atenção:**  
   > O uso de políticas FullAccess fornece permissões amplas. Em ambientes de produção, é recomendável criar políticas com o princípio do menor privilégio, limitando permissões apenas ao necessário e restringindo recursos via ARNs.



5. **Configurar o GitHub Actions**  
   - Configure as variáveis de ambiente no GitHub Actions Secrets and Variables, por exemplo:

    ```yaml
    vars:
      AWS_REGION
      STATEFILE_BUCKET_NAME_TF_DEV
    secrets:
      AWS_ASSUME_ROLE_ARN_DEV
      AWS_ACCOUNT_ID_DEV
    ```

6. **Configurar o arquivo de destroy_config.json**

   ```json
      {
         "dev": false
      }
   ```