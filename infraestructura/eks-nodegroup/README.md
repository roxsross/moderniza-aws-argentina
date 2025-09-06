# 🚀 Guía de Despliegue EKS con Node Groups usando CloudFormation

Esta guía te permite crear un cluster EKS tradicional con Node Groups gestionados usando CloudFormation y scripts automatizados.

## 📋 Prerrequisitos

1. **AWS CLI** configurado con credenciales válidas
2. **kubectl** instalado
3. **Helm** instalado
4. **Roles IAM** creados (ejecutar primero el stack de IAM)

## 🔧 Archivos Incluidos

- `eks-nodegroup.yaml` - Template de CloudFormation para crear el cluster EKS
- `deploy-cluster.sh` - Script automatizado para desplegar usando CloudFormation

## 🚀 Pasos de Despliegue

### Opción 1: Usando CloudFormation Template (Recomendado para producción)

#### 1. Crear Roles IAM (una sola vez)

```bash
cd ../iam-role
./deploy-stack.sh
```

#### 2. Desplegar usando CloudFormation

```bash
# Desplegar el stack de CloudFormation
aws cloudformation create-stack \
  --stack-name petclinic-eks-cluster \
  --template-body file://eks-nodegroup.yaml \
  --capabilities CAPABILITY_IAM \
  --region us-east-1

# Esperar a que el stack se complete
aws cloudformation wait stack-create-complete \
  --stack-name petclinic-eks-cluster \
  --region us-east-1
```

#### 3. Configurar kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name petclinic-cluster
```

### Opción 2: Usando Script Automatizado (Recomendado para desarrollo)

#### 1. Crear Roles IAM (una sola vez)

```bash
cd ../iam-role
./deploy-stack.sh
```

#### 2. Ejecutar script automatizado

```bash
# El script se encarga de todo: crear cluster, configurar kubectl, instalar Load Balancer Controller
./deploy-cluster.sh
```

> **Nota:** El script `deploy-cluster.sh` usa CloudFormation internamente y configura automáticamente:
> - Despliegue del stack de CloudFormation
> - Cluster EKS con Node Groups
> - AWS Load Balancer Controller
> - Namespace para la aplicación
> - Configuración de kubectl

## 🎯 Verificación

```bash
# Ver estado del cluster
kubectl cluster-info

# Ver nodos
kubectl get nodes

# Ver pods del sistema
kubectl get pods --all-namespaces

# Ver node groups
aws eks describe-nodegroup \
  --cluster-name petclinic-cluster \
  --nodegroup-name petclinic-nodes \
  --region us-east-1

# Verificar el Load Balancer Controller (si usaste el script)
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# Ver el namespace de la aplicación
kubectl get namespaces | grep petclinic
```

## 🧹 Limpieza

### Si usaste CloudFormation:

```bash
# Eliminar el stack completo
aws cloudformation delete-stack \
  --stack-name petclinic-eks-cluster \
  --region us-east-1
```

### Si usaste el script deploy-cluster.sh:

```bash
# El script usa CloudFormation internamente, así que eliminar el stack
aws cloudformation delete-stack \
  --stack-name petclinic-eks-cluster \
  --region us-east-1

# También eliminar recursos adicionales del Load Balancer Controller
aws iam detach-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy

aws iam delete-role --role-name AmazonEKSLoadBalancerControllerRole

aws iam delete-policy \
  --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy
```

## 🔧 Personalización

### Parámetros del CloudFormation Template:

- `ClusterName` (default: petclinic-cluster)
- `KubernetesVersion` (default: 1.30)
- `VpcBlock` (default: 192.168.0.0/16)
- `PublicSubnet01Block` y `PublicSubnet02Block`
- `PrivateSubnet01Block` y `PrivateSubnet02Block`

### Ejemplo de personalización:

```bash
aws cloudformation create-stack \
  --stack-name petclinic-eks-cluster \
  --template-body file://eks-nodegroup.yaml \
  --parameters ParameterKey=ClusterName,ParameterValue=mi-cluster-personalizado \
               ParameterKey=KubernetesVersion,ParameterValue=1.29 \
  --capabilities CAPABILITY_IAM \
  --region us-east-1
```

## 📝 Notas

- **CloudFormation directo**: Ideal para entornos de producción, control total de parámetros
- **Script deploy-cluster.sh**: Ideal para desarrollo rápido, incluye configuraciones adicionales automáticamente (también usa CloudFormation)
- El cluster tarda **15-20 minutos** en crearse completamente
- Incluye configuración completa de VPC con subredes públicas y privadas
- Los Node Groups se despliegan en subredes privadas para mayor seguridad
- Ambas opciones usan CloudFormation como base para garantizar consistencia
