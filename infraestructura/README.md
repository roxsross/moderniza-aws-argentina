# Infraestructura EKS para Spring PetClinic

Esta carpeta contiene los archivos necesarios para desplegar la infraestructura de Amazon EKS que soportará la aplicación Spring PetClinic modernizada.

## Archivos incluidos

- `eksctl-cluster.yaml` - Configuración del cluster EKS con eksctl
- `deploy-cluster.sh` - Script automatizado para desplegar el cluster
- `iam-role/` - Roles IAM necesarios (CloudFormation)

## Prerrequisitos

1. **Herramientas instaladas:**
   - [eksctl](https://eksctl.io/) 
   - [kubectl](https://kubernetes.io/docs/tasks/tools/)
   - [AWS CLI](https://docs.aws.amazon.com/cli/) configurado
   - [Helm](https://helm.sh/docs/intro/install/) (para Load Balancer Controller)

2. **Permisos AWS:**
   - Despliega primero el CloudFormation template en `iam-role/cloudformation.yaml`
   - Asocia la policy resultante a tu Permission Set de AWS SSO

## Despliegue rápido

```bash
# 1. Desplegar roles IAM (solo una vez)
aws cloudformation create-stack \
  --stack-name eks-mcp-permissions \
  --template-body file://iam-role/cloudformation.yaml \
  --capabilities CAPABILITY_NAMED_IAM

# 1.1 Desplegar roles IAM Adicionales (solo una vez)
aws cloudformation create-stack \
  --stack-name eks-mcp-permissions \
  --template-body file://iam-role/cloudformation-additional.yaml \
  --capabilities CAPABILITY_NAMED_IAM

# 2. Ejecutar el script de despliegue
./deploy-cluster.sh
```

## Configuración del cluster

El cluster EKS incluye:

- **Nombre:** `petclinic-cluster`
- **Región:** `us-east-1`
- **Kubernetes:** v1.30
- **VPC:** Dedicada con subnets públicas y privadas
- **Nodos:** 2-4 instancias t3.medium (auto-scaling)
- **Addons:** VPC CNI, CoreDNS, kube-proxy, AWS Load Balancer Controller
- **Logging:** CloudWatch habilitado para todos los componentes

## Arquitectura de red

```
VPC (10.0.0.0/16)
├── Subnets públicas
│   ├── us-east-1a (10.0.1.0/24)
│   └── us-east-1b (10.0.2.0/24)
└── Subnets privadas
    ├── us-east-1a (10.0.101.0/24)
    └── us-east-1b (10.0.102.0/24)
```

## Verificación post-despliegue

```bash
# Verificar nodos
kubectl get nodes

# Verificar namespace
kubectl get ns petclinic

# Verificar Load Balancer Controller
kubectl get deployment -n kube-system aws-load-balancer-controller
```

## Limpieza

Para eliminar todos los recursos:

```bash
# Eliminar el cluster (esto eliminará también la VPC y todos los recursos asociados)
eksctl delete cluster --name petclinic-cluster

# Eliminar roles IAM (opcional)
aws cloudformation delete-stack --stack-name eks-mcp-permissions
aws cloudformation delete-stack --stack-name eks-mcp-additional-permissions
```

## Costos estimados

- **EKS Cluster:** ~$73/mes
- **EC2 Instances (2x t3.medium):** ~$60/mes
- **EBS Volumes:** ~$4/mes
- **NAT Gateway:** ~$45/mes
- **Total aproximado:** ~$182/mes

💡 **Tip:** Para desarrollo, puedes usar Fargate Spot o instancias más pequeñas para reducir costos.

## Troubleshooting

### Error: Roles IAM no encontrados
```bash
# Verificar que los roles existen
aws iam get-role --role-name EKSClusterRole-eks-mcp-permissions
aws iam get-role --role-name EKSNodegroupRole-eks-mcp-permissions
```

### Error: Permisos insuficientes
Verifica que tu usuario/rol tenga la policy `AmazonQDeveloperEKSMCPPolicy` asociada.

### Nodos no se unen al cluster
Verifica que las subnets privadas tengan acceso a internet a través del NAT Gateway.

## Integración con Amazon Q Developer

Una vez desplegado el cluster, puedes usar Amazon Q Developer CLI con el EKS MCP Server para:

- Generar Helm Charts
- Desplegar aplicaciones
- Monitorear el cluster
- Troubleshooting automatizado

Consulta el `../agent/README.md` para la guía completa de uso con Amazon Q Developer.
