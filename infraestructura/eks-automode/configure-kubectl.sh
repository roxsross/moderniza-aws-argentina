#!/bin/bash

# Variables configurables
CLUSTER_NAME=${CLUSTER_NAME:-"petclinic-automode-cluster"}
AWS_REGION=${AWS_REGION:-"us-east-1"}

echo "🚀 Configurando kubectl para el cluster $CLUSTER_NAME..."

# Configurar kubectl para conectarse al cluster
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

echo "✅ kubectl configurado correctamente"

# Verificar la conexión
echo "🔍 Verificando conexión al cluster..."
kubectl cluster-info

echo "📋 Información de nodos:"
kubectl get nodes

echo "🎯 Cluster EKS '$CLUSTER_NAME' está listo!"
