# 🚀 Guía de Despliegue EKS Auto Mode

Esta guía te permite crear un cluster EKS con Auto Mode de forma estandarizada.

## 📋 Prerrequisitos

1. **AWS CLI** configurado con credenciales válidas
2. **kubectl** instalado
3. **Roles IAM** creados (ejecutar primero el stack de IAM)

## 🔧 Variables de Configuración

Puedes personalizar los siguientes valores:

```bash
export CLUSTER_NAME="petclinic-automode-cluster"  # Nombre del cluster
export AWS_REGION="us-east-1"                     # Región AWS
export STACK_NAME="eks-mcp-permissions"           # Nombre del stack de IAM
```

## 🚀 Pasos de Despliegue

### 1. Crear Roles IAM (una sola vez)

```bash
cd ../iam-role
./deploy-stack.sh
```

### 2. Crear Cluster EKS

```bash
./create-eks-cluster.sh
```

### 3. Configurar kubectl

```bash
./configure-kubectl.sh
```

### 4. Habilitar Auto Mode

```bash
./enable-automode.sh
```

## 🎯 Verificación

```bash
# Ver estado del cluster
kubectl cluster-info

# Ver nodos (aparecerán cuando se desplieguen workloads)
kubectl get nodes

# Ver pods del sistema
kubectl get pods --all-namespaces
```

## 🧹 Limpieza

Para eliminar el cluster:

```bash
aws eks delete-cluster --name $CLUSTER_NAME --region $AWS_REGION
```

## 📝 Notas

- El cluster tarda **10-15 minutos** en crearse
- Los nodos aparecen automáticamente cuando se despliegan aplicaciones
- Auto Mode gestiona automáticamente escalado, almacenamiento y balanceadores
