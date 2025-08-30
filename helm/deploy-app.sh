#!/bin/bash

# Script para desplegar Spring PetClinic usando Helm
set -e

CHART_NAME="spring-petclinic"
NAMESPACE="petclinic"
RELEASE_NAME="petclinic-app"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Desplegando Spring PetClinic con Helm...${NC}"

# Verificar que kubectl está configurado
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ kubectl no está configurado correctamente${NC}"
    exit 1
fi

# Verificar que Helm está instalado
if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ Helm no está instalado${NC}"
    exit 1
fi

# Verificar parámetros
if [ -z "$1" ]; then
    echo -e "${RED}❌ Uso: $0 <ECR_IMAGE_URI>${NC}"
    echo -e "${YELLOW}Ejemplo: $0 123456789012.dkr.ecr.us-east-1.amazonaws.com/spring-petclinic:latest${NC}"
    exit 1
fi

ECR_IMAGE_URI=$1

echo -e "${GREEN}📦 Usando imagen: ${ECR_IMAGE_URI}${NC}"

# Crear namespace si no existe
echo -e "${GREEN}📁 Creando namespace ${NAMESPACE}...${NC}"
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Desplegar con Helm
echo -e "${GREEN}🎯 Desplegando aplicación...${NC}"
helm upgrade --install ${RELEASE_NAME} ./helm/${CHART_NAME} \
    --namespace ${NAMESPACE} \
    --set image.repository=$(echo ${ECR_IMAGE_URI} | cut -d':' -f1) \
    --set image.tag=$(echo ${ECR_IMAGE_URI} | cut -d':' -f2) \
    --wait \
    --timeout=10m

# Verificar el despliegue
echo -e "${GREEN}🔍 Verificando despliegue...${NC}"
kubectl get pods -n ${NAMESPACE}
kubectl get svc -n ${NAMESPACE}

# Obtener la URL del LoadBalancer
echo -e "${GREEN}🌐 Obteniendo URL del LoadBalancer...${NC}"
echo -e "${YELLOW}Esperando que el LoadBalancer obtenga una IP externa...${NC}"

# Esperar hasta que el LoadBalancer tenga una IP externa
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get svc ${RELEASE_NAME} -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ ! -z "$EXTERNAL_IP" ]; then
        echo -e "${GREEN}✅ Aplicación desplegada exitosamente!${NC}"
        echo -e "${GREEN}🔗 URL: http://${EXTERNAL_IP}${NC}"
        break
    fi
    echo -e "${YELLOW}Esperando LoadBalancer... (${i}/30)${NC}"
    sleep 10
done

if [ -z "$EXTERNAL_IP" ]; then
    echo -e "${YELLOW}⚠️  LoadBalancer aún no tiene IP externa. Verifica manualmente con:${NC}"
    echo -e "${YELLOW}   kubectl get svc -n ${NAMESPACE}${NC}"
fi

echo -e "${GREEN}📋 Comandos útiles:${NC}"
echo -e "   Ver pods: kubectl get pods -n ${NAMESPACE}"
echo -e "   Ver logs: kubectl logs -f deployment/${RELEASE_NAME} -n ${NAMESPACE}"
echo -e "   Ver servicio: kubectl get svc -n ${NAMESPACE}"
