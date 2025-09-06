#!/bin/bash

# Script para desplegar el cluster EKS para Spring PetClinic usando CloudFormation
# Automatiza el proceso de creación del cluster y configuración inicial

set -e

# Variables de configuración
STACK_NAME="petclinic-eks-cluster"
CLUSTER_NAME="petclinic-cluster"
AWS_REGION="us-east-1"
CF_TEMPLATE="eks-nodegroup.yaml"

echo "🚀 Iniciando despliegue del cluster EKS para Spring PetClinic usando CloudFormation..."

# Verificar prerrequisitos
echo "📋 Verificando prerrequisitos..."

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl no está instalado. Instálalo desde: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "❌ helm no está instalado. Instálalo desde: https://helm.sh/"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI no está configurado correctamente"
    exit 1
fi

if [ ! -f "$CF_TEMPLATE" ]; then
    echo "❌ Template de CloudFormation no encontrado: $CF_TEMPLATE"
    exit 1
fi

echo "✅ Prerrequisitos verificados"

# Verificar que los roles IAM existen
echo "🔐 Verificando roles IAM..."
if ! aws iam get-role --role-name EKSClusterRole-eks-mcp-permissions &> /dev/null; then
    echo "❌ El rol EKSClusterRole-eks-mcp-permissions no existe."
    echo "   Despliega primero el CloudFormation template: infraestructura/iam-role/cloudformation.yaml"
    echo "   Luego despliega el CloudFormation template con permisos adicionales: infraestructura/iam-role/cloudformation-additional.yaml"
    exit 1
fi

if ! aws iam get-role --role-name EKSNodegroupRole-eks-mcp-permissions &> /dev/null; then
    echo "❌ El rol EKSNodegroupRole-eks-mcp-permissions no existe."
    echo "   Despliega primero el CloudFormation template: infraestructura/iam-role/cloudformation.yaml"
    echo "   Luego despliega el CloudFormation template con permisos adicionales: infraestructura/iam-role/cloudformation-additional.yaml"
    exit 1
fi

echo "✅ Roles IAM verificados"

# Verificar si el stack ya existe
echo "🔍 Verificando si el stack ya existe..."
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" &> /dev/null; then
    echo "⚠️  El stack $STACK_NAME ya existe."
    echo "   Estado del stack:"
    aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" --query 'Stacks[0].StackStatus' --output text
    read -p "¿Deseas continuar y actualizar el stack? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Operación cancelada"
        exit 1
    fi
    OPERATION="update-stack"
else
    OPERATION="create-stack"
fi

# Crear o actualizar el cluster usando CloudFormation
echo "🏗️  Desplegando cluster EKS usando CloudFormation (esto tomará ~15-20 minutos)..."
aws cloudformation $OPERATION \
    --stack-name "$STACK_NAME" \
    --template-body file://"$CF_TEMPLATE" \
    --capabilities CAPABILITY_IAM \
    --region "$AWS_REGION" \
    --no-cli-pager

# Esperar a que se complete la operación
if [ "$OPERATION" = "create-stack" ]; then
    echo "⏳ Esperando a que se complete la creación del stack..."
    aws cloudformation wait stack-create-complete \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION"
else
    echo "⏳ Esperando a que se complete la actualización del stack..."
    aws cloudformation wait stack-update-complete \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION"
fi

echo "✅ Stack de CloudFormation completado exitosamente"

# Configurar kubectl
echo "⚙️  Configurando kubectl..."
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

# Verificar que el cluster está funcionando
echo "🔍 Verificando el cluster..."
kubectl get nodes

# Crear namespace para la aplicación
echo "📦 Creando namespace petclinic..."
kubectl create namespace petclinic --dry-run=client -o yaml | kubectl apply -f -

# Instalar AWS Load Balancer Controller
echo "⚖️  Configurando AWS Load Balancer Controller..."

# Descargar la política IAM para el Load Balancer Controller
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

# Crear la política IAM (ignorar si ya existe)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy"

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json \
    --no-cli-pager 2>/dev/null || echo "ℹ️  Policy already exists, continuing..."

rm -f iam_policy.json

# Crear el rol IAM para el service account usando AWS CLI
ROLE_NAME="AmazonEKSLoadBalancerControllerRole"
OIDC_ISSUER=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query "cluster.identity.oidc.issuer" --output text | sed 's|https://||')

# Crear el trust policy para IRSA
cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/$OIDC_ISSUER"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "$OIDC_ISSUER:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
}
EOF

# Crear el rol IAM
aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file://trust-policy.json \
    --no-cli-pager 2>/dev/null || echo "ℹ️  Role already exists, continuing..."

# Adjuntar la política al rol
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN" \
    --no-cli-pager 2>/dev/null || echo "ℹ️  Policy already attached, continuing..."

rm -f trust-policy.json

# Crear el service account con anotaciones
kubectl apply -f - << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME
EOF

# Instalar el Load Balancer Controller usando Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --wait

echo ""
echo "✅ Cluster EKS desplegado exitosamente usando CloudFormation!"
echo ""
echo "📋 Información del cluster:"
echo "   Nombre: $CLUSTER_NAME"
echo "   Región: $AWS_REGION"
echo "   Stack: $STACK_NAME"
echo "   Namespace: petclinic"
echo ""
echo "� Verificación final:"
kubectl get nodes
echo ""
kubectl get pods -n kube-system | grep aws-load-balancer-controller || echo "⚠️  Load Balancer Controller no está disponible aún"
echo ""
echo "�🔧 Próximos pasos:"
echo "   1. Construir y subir la imagen Docker a ECR"
echo "   2. Crear el Helm Chart para la aplicación"
echo "   3. Desplegar la aplicación usando Helm"
echo ""
echo "💡 Usa Amazon Q Developer CLI con EKS MCP Server para los siguientes pasos!"
echo ""
echo "🧹 Para eliminar el cluster más tarde:"
echo "   aws cloudformation delete-stack --stack-name $STACK_NAME --region $AWS_REGION"
