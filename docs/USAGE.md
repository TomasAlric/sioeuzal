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

#### Acionamento do Pipeline

- Push para qualquer branch: Aciona deploy
- Alterar `destroy_config.json` para `true`: Aciona destroy dos recursos
