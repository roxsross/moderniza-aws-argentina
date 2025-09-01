#!/bin/bash

# Variables configurables
CLUSTER_NAME=${CLUSTER_NAME:-"petclinic-automode-cluster"}
AWS_REGION=${AWS_REGION:-"us-east-1"}
STACK_NAME=${STACK_NAME:-"eks-mcp-permissions"}

# Obtener ARN del rol del cluster dinámicamente
CLUSTER_ROLE_ARN=$(aws iam get-role --role-name "EKSClusterRole-$STACK_NAME" --query 'Role.Arn' --output text --region $AWS_REGION)

echo "🚀 Creando cluster EKS: $CLUSTER_NAME"
echo "📍 Región: $AWS_REGION"
echo "🔑 Rol del cluster: $CLUSTER_ROLE_ARN"

# Obtener VPC por defecto y subnets
echo "🔍 Obteniendo configuración de red..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region $AWS_REGION)
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[?AvailabilityZone!=`'$AWS_REGION'e`].SubnetId' --output text --region $AWS_REGION | tr '\t' ',')

echo "📋 VPC: $VPC_ID"
echo "📋 Subnets: $SUBNET_IDS"

# Crear archivo de configuración temporal
cat > /tmp/cluster-config.json << EOF
{
  "name": "$CLUSTER_NAME",
  "version": "1.31",
  "roleArn": "$CLUSTER_ROLE_ARN",
  "resourcesVpcConfig": {
    "subnetIds": ["$(echo $SUBNET_IDS | sed 's/,/","/g')"],
    "endpointPublicAccess": true,
    "endpointPrivateAccess": true
  },
  "logging": {
    "clusterLogging": [
      {
        "types": ["api", "audit", "authenticator", "controllerManager", "scheduler"],
        "enabled": true
      }
    ]
  },
  "tags": {
    "Environment": "demo",
    "Project": "petclinic-modernization",
    "ManagedBy": "amazon-q-developer"
  }
}
EOF

# Crear el cluster
echo "⚡ Creando cluster EKS..."
aws eks create-cluster \
  --cli-input-json file:///tmp/cluster-config.json \
  --region $AWS_REGION

if [ $? -eq 0 ]; then
    echo "✅ Cluster EKS creado exitosamente!"
    echo "⏳ El cluster tardará 10-15 minutos en estar listo"
    echo ""
    echo "📝 Próximos pasos:"
    echo "1. Esperar a que el cluster esté ACTIVE"
    echo "2. Ejecutar: ./configure-kubectl.sh"
    echo "3. Ejecutar: ./enable-automode.sh"
else
    echo "❌ Error creando el cluster"
    exit 1
fi

# Limpiar archivo temporal
rm -f /tmp/cluster-config.json
