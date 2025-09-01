# 🚀 Guía de Despliegue EKS con Node Groups

Esta guía te permite crear un cluster EKS tradicional con Node Groups gestionados de forma estandarizada.

## 📋 Prerrequisitos

1. **AWS CLI** configurado con credenciales válidas
2. **kubectl** instalado
3. **Roles IAM** creados (ejecutar primero el stack de IAM)

## 🔧 Variables de Configuración

Puedes personalizar los siguientes valores:

```bash
export CLUSTER_NAME="petclinic-cluster"           # Nombre del cluster
export AWS_REGION="us-east-1"                     # Región AWS
export STACK_NAME="eks-mcp-permissions"           # Nombre del stack de IAM
export NODE_GROUP_NAME="petclinic-nodes"          # Nombre del node group
export INSTANCE_TYPE="t3.medium"                  # Tipo de instancia
export MIN_SIZE="1"                                # Mínimo de nodos
export MAX_SIZE="3"                                # Máximo de nodos
export DESIRED_SIZE="2"                            # Nodos deseados
```

## 🚀 Pasos de Despliegue

### 1. Crear Roles IAM (una sola vez)

```bash
cd ../iam-role
./deploy-stack.sh
```

### 2. Crear Cluster EKS con Node Groups

```bash
./deploy-cluster.sh
```

### 3. Configurar kubectl

```bash
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
```

## 🎯 Verificación

```bash
# Ver estado del cluster
kubectl cluster-info

# Ver nodos
kubectl get nodes

# Ver pods del sistema
kubectl get pods --all-namespaces

# Ver node groups
aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODE_GROUP_NAME --region $AWS_REGION
```

## 🧹 Limpieza

Para eliminar el cluster:

```bash
# Eliminar node group primero
aws eks delete-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODE_GROUP_NAME --region $AWS_REGION

# Esperar a que se elimine, luego eliminar cluster
aws eks delete-cluster --name $CLUSTER_NAME --region $AWS_REGION
```

## 📝 Notas

- El cluster tarda **10-15 minutos** en crearse
- Los node groups tardan **5-10 minutos** adicionales
- Los nodos están siempre disponibles (no como Auto Mode)
- Requiere gestión manual del escalado y actualizaciones
