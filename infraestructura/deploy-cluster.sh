#!/bin/bash

# Script para desplegar el cluster EKS para Spring PetClinic
# Basado en la guía del README en la carpeta agent

set -e

echo "🚀 Iniciando despliegue del cluster EKS para Spring PetClinic..."

# Verificar prerrequisitos
echo "📋 Verificando prerrequisitos..."

if ! command -v eksctl &> /dev/null; then
    echo "❌ eksctl no está instalado. Instálalo desde: https://eksctl.io/"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl no está instalado. Instálalo desde: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI no está configurado correctamente"
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

# Crear el cluster
echo "🏗️  Creando cluster EKS (esto tomará ~15-20 minutos)..."
eksctl create cluster -f ./eksctl-cluster.yaml

# Verificar que el cluster está funcionando
echo "🔍 Verificando el cluster..."
kubectl get nodes

# Crear namespace para la aplicación
echo "📦 Creando namespace petclinic..."
kubectl create namespace petclinic --dry-run=client -o yaml | kubectl apply -f -

# Instalar AWS Load Balancer Controller
echo "⚖️  Configurando AWS Load Balancer Controller..."
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json \
    --no-cli-pager || echo "Policy already exists"

rm iam_policy.json

# Crear service account para el Load Balancer Controller
eksctl create iamserviceaccount \
  --cluster=petclinic-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
  --approve || echo "Service account already exists"

# Instalar el Load Balancer Controller usando Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=petclinic-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller || echo "Controller already installed"

echo "✅ Cluster EKS desplegado exitosamente!"
echo ""
echo "📋 Información del cluster:"
echo "   Nombre: petclinic-cluster"
echo "   Región: us-east-1"
echo "   Namespace: petclinic"
echo ""
echo "🔧 Próximos pasos:"
echo "   1. Construir y subir la imagen Docker a ECR"
echo "   2. Crear el Helm Chart para la aplicación"
echo "   3. Desplegar la aplicación usando Helm"
echo ""
echo "💡 Usa Amazon Q Developer CLI con EKS MCP Server para los siguientes pasos!"
