#!/bin/bash

# Variables configurables
CLUSTER_NAME=${CLUSTER_NAME:-"petclinic-automode-cluster"}
AWS_REGION=${AWS_REGION:-"us-east-1"}
STACK_NAME=${STACK_NAME:-"eks-mcp-permissions"}

# Obtener ARNs de roles dinámicamente
CLUSTER_ROLE_ARN=$(aws iam get-role --role-name "EKSClusterRole-$STACK_NAME" --query 'Role.Arn' --output text --region $AWS_REGION)
NODE_ROLE_ARN=$(aws iam get-role --role-name "EKSNodegroupRole-$STACK_NAME" --query 'Role.Arn' --output text --region $AWS_REGION)

echo "🔄 Habilitando EKS Auto Mode para $CLUSTER_NAME..."

# Verificar que el cluster esté activo
CLUSTER_STATUS=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query 'cluster.status' --output text)

if [ "$CLUSTER_STATUS" != "ACTIVE" ]; then
    echo "❌ El cluster no está activo aún. Estado actual: $CLUSTER_STATUS"
    echo "⏳ Espera a que el cluster esté en estado ACTIVE antes de habilitar Auto Mode"
    exit 1
fi

echo "✅ Cluster está activo. Habilitando Auto Mode..."
echo "📋 Usando roles:"
echo "   - Cluster: $CLUSTER_ROLE_ARN"
echo "   - Nodos: $NODE_ROLE_ARN"

# Cambiar modo de autenticación si es necesario
CURRENT_AUTH_MODE=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query 'cluster.accessConfig.authenticationMode' --output text)

if [ "$CURRENT_AUTH_MODE" = "CONFIG_MAP" ]; then
    echo "🔄 Cambiando modo de autenticación..."
    aws eks update-cluster-config \
        --name $CLUSTER_NAME \
        --access-config '{"authenticationMode":"API_AND_CONFIG_MAP"}' \
        --region $AWS_REGION
    
    echo "⏳ Esperando cambio de autenticación..."
    sleep 30
fi

# Habilitar Auto Mode
aws eks update-cluster-config \
    --name $CLUSTER_NAME \
    --compute-config "{\"enabled\":true,\"nodeRoleArn\":\"$NODE_ROLE_ARN\",\"nodePools\":[\"general-purpose\"]}" \
    --storage-config '{"blockStorage":{"enabled":true}}' \
    --kubernetes-network-config '{"elasticLoadBalancing":{"enabled":true}}' \
    --region $AWS_REGION

echo "✅ EKS Auto Mode habilitado correctamente!"
echo "🎯 El cluster ahora gestionará automáticamente:"
echo "   - Escalado de nodos"
echo "   - Escalado de pods"
echo "   - Almacenamiento persistente"
echo "   - Balanceadores de carga"
