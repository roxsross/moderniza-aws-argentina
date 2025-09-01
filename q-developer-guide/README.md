# Guía paso a paso: Modernización con Amazon Q Developer y EKS MCP Server

Esta guía te ayudará a desplegar el proyecto Spring PetClinic en Amazon EKS usando Amazon Q Developer CLI con el EKS MCP Server, y luego modernizarlo a Java 21 + Spring Boot 3.5.

## Prerrequisitos

Antes de comenzar, asegúrate de tener:

- [Amazon Q Developer CLI](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-installing.html) instalado
- [Python 3.10+](https://www.python.org/downloads/release/python-3100/) instalado
- [uv package manager](https://docs.astral.sh/uv/getting-started/installation/) instalado
- [AWS CLI configurado](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) con credenciales
- Acceso a AWS con permisos para crear recursos EKS, VPC, CloudFormation
- **Importante**: Los templates de CloudFormation `infraestructura/iam-role` desplegados

### 0.1 Desplegar los permisos IAM necesarios

Antes de comenzar con Amazon Q Developer, despliega el CloudFormation template que crea los permisos necesarios:

```bash
aws cloudformation create-stack \
  --stack-name eks-mcp-permissions \
  --template-body file://infraestructura/iam-role/cloudformation.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=PolicyName,ParameterValue=AmazonQDeveloperEKSMCPPolicy
```

```bash
aws cloudformation create-stack \
  --stack-name eks-mcp-additional-permissions \
  --template-body file://infraestructura/iam-role/cloudformation-additional.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=PolicyName,ParameterValue=AmazonQDeveloperEKSMCPAdditionalPolicy
```

### 0.2 Asociar la policy al Permission Set de SSO

Una vez desplegado el stack, obtén el ARN de la policy:

```bash
aws cloudformation describe-stacks \
  --stack-name eks-mcp-permissions \
  --query 'Stacks[0].Outputs[?OutputKey==`ManagedPolicyArn`].OutputValue' \
  --output text
```

```bash
aws cloudformation describe-stacks \
  --stack-name eks-mcp-additional-permissions \
  --query 'Stacks[0].Outputs[?OutputKey==`AdditionalPolicyArn`].OutputValue' \
  --output text
```

Luego asocia esta policy a tu Permission Set en AWS SSO Identity Center.

### 0.3 Verificar permisos

Para verificar que tienes los permisos correctos, ejecuta:

```bash
# Verificar acceso a EKS
aws eks list-clusters

# Verificar acceso a ECR
aws ecr describe-repositories

# Verificar acceso a CloudFormation
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE
```

## Paso 1: Configurar Amazon Q Developer CLI con EKS MCP Server

### 1.1 Configurar el archivo mcp.json

Edita tu archivo de configuración MCP del Q Developer CLI (`mcp.json`) para incluir el EKS MCP Server:

```json
{
  "mcpServers": {
    "awslabs.eks-mcp-server": {
      "command": "uvx",
      "args": [
        "awslabs.eks-mcp-server@latest",
        "--allow-write",
        "--allow-sensitive-data-access"
      ],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR"        
      },
      "autoApprove": [],
      "disabled": false
    }
  }
}
```

### 1.2 Verificar la configuración

Ejecuta el siguiente comando para verificar que el EKS MCP Server esté disponible:

```bash
q dev /tools
```

Deberías ver las herramientas del EKS MCP Server listadas.

## Paso 2: Crear un Helm Chart para el repositorio

Usa Amazon Q Developer con comandos en lenguaje natural:

```
"Crea un Helm Chart para una aplicación Spring Boot llamada 'spring-petclinic' que:
- Use la imagen que construiré desde el Dockerfile actual
- Exponga el puerto 8080
- Incluya un Service de tipo LoadBalancer
- Configure 2 réplicas por defecto
- Incluya health checks apropiados para Spring Boot Actuator
- Use un namespace llamado 'petclinic'"
```

El EKS MCP Server generará automáticamente:
- Estructura del Helm Chart con templates
- `deployment.yaml` con las configuraciones apropiadas
- `service.yaml` para exponer la aplicación
- `values.yaml` con valores configurables

## Paso 3: Crear el Cluster de EKS

En lugar de crear manualmente CloudFormation, usa el EKS MCP Server:

```
"Crea un cluster de EKS llamado 'petclinic-cluster' con:
- VPC dedicada con subnets públicas y privadas
- Managed Node Group con instancias t3.medium
- 2-4 nodos escalables automáticamente
- Habilitado para LoadBalancers
- Configuración de logs de CloudWatch
- En la región us-east-1
- Usa los roles IAM existentes: EKSClusterRole-eks-mcp-permissions y EKSNodegroupRole-eks-mcp-permissions del stack CloudFormation"
```

El MCP Server ejecutará automáticamente:
- Creación de CloudFormation stack con VPC, subnets, IGW, NAT
- Creación del cluster EKS con roles IAM apropiados
- Configuración del Managed Node Group
- Setup de acceso kubectl

⏰ **Nota**: La creación del cluster toma aproximadamente 15-20 minutos.

## Paso 4: Construir y subir la imagen Docker

Mientras el cluster se crea, prepara la imagen:

```
"Ayúdame a construir la imagen Docker del proyecto Spring PetClinic y subirla a Amazon ECR:
- Crea un repositorio ECR llamado 'spring-petclinic'
- Construye la imagen usando el Dockerfile actual
- Tagea la imagen apropiadamente
- Sube la imagen al repositorio ECR"
```

## Paso 5: Desplegar el Helm Chart

Una vez que el cluster esté listo y la imagen subida:

```
"Despliega el Helm Chart de spring-petclinic en el cluster EKS 'petclinic-cluster':
- Usa la imagen que subí a ECR
- Aplica el chart en el namespace 'petclinic'
- Configura las variables de entorno necesarias
- Muéstrame el status del deployment y los pods"
```

## Paso 6: Obtener la URL del proyecto

Para acceder a tu aplicación:

```
"Muéstrame la URL pública de la aplicación spring-petclinic:
- Lista los servicios en el namespace petclinic
- Obtén la URL del LoadBalancer
- Verifica que la aplicación esté respondiendo correctamente"
```

## Paso 7: Modernizar a Java 21 + Spring Boot 3.5

Una vez que confirmes que la aplicación funciona, procede con la modernización:

### 7.1 Actualizar build.gradle

```
"Actualiza el archivo build.gradle para usar:
- Java 21 como sourceCompatibility
- Spring Boot 3.5.x como versión
- Actualiza todas las dependencias compatibles
- Mantén la funcionalidad actual de la aplicación"
```

### 7.2 Actualizar Dockerfile

```
"Modifica el Dockerfile para:
- Usar Amazon Corretto 21 como imagen base
- Mantener la estructura multi-stage actual
- Asegurar compatibilidad con la nueva versión de Java"
```

### 7.3 Verificar compatibilidad

```
"Analiza el código fuente para identificar:
- Dependencias que necesiten actualización para Spring Boot 3.5
- Posibles problemas de compatibilidad con Java 21
- Cambios necesarios en la configuración"
```

### 7.4 Redesplegar con las nuevas versiones

```
"Reconstruye y redespliega la aplicación actualizada:
- Construye la nueva imagen con Java 21
- Sube la imagen actualizada a ECR
- Actualiza el deployment en EKS con la nueva imagen
- Verifica que todo funcione correctamente"
```

## Comandos útiles durante el proceso

### Monitoreo y troubleshooting

```
"Muéstrame el estado de salud del cluster petclinic-cluster:
- Status de los nodos
- Pods corriendo y su estado
- Logs de la aplicación si hay errores
- Métricas de CPU y memoria"
```

### Verificar logs

```
"Obtén los logs de los pods de spring-petclinic de los últimos 10 minutos para diagnosticar cualquier problema"
```

### Gestión de recursos

```
"Lista todos los recursos de Kubernetes en el namespace petclinic y muéstrame su estado actual"
```

## Consideraciones de seguridad

- ✅ El CloudFormation template incluye roles IAM con permisos mínimos necesarios
- ✅ Las credenciales se gestionan a través de AWS SSO y Permission Sets
- ✅ No expongas secretos en los manifiestos YAML - usa AWS Secrets Manager
- ✅ El EKS MCP Server usa accesos temporales y autenticación segura

## Troubleshooting común

### Si tienes problemas de permisos:

También puedes verificar manualmente:

```bash
# Verificar que puedes asumir el rol del cluster
aws sts get-caller-identity

# Verificar que puedes acceder a los roles creados
aws iam get-role --role-name EKSClusterRole-eks-mcp-permissions
aws iam get-role --role-name EKSNodegroupRole-eks-mcp-permissions
```

### Si el cluster no se crea correctamente:

```
"Analiza los errores del stack de CloudFormation para el cluster petclinic-cluster y dame recomendaciones para solucionarlo"
```

### Si los pods no inician:

```
"Diagnóstica por qué los pods de spring-petclinic no están iniciando y dame los pasos para solucionarlo"
```

### Si hay problemas de red:

```
"Verifica la configuración de red del cluster petclinic-cluster y asegúrate de que los LoadBalancers puedan acceder a los pods"
```

## Limpieza de recursos

Al finalizar las pruebas:

```
"Elimina todos los recursos creados para el proyecto petclinic:
- Elimina el Helm deployment
- Elimina el cluster EKS y todos sus recursos asociados
- Elimina las imágenes ECR
- Verifica que no queden recursos cobrando en AWS"
```

### Limpieza manual adicional

Si deseas eliminar también los permisos IAM:

```bash
# Eliminar el stack de permisos
aws cloudformation delete-stack --stack-name eks-mcp-permissions
aws cloudformation delete-stack --stack-name eks-mcp-additional-permissions

# Verificar que se eliminó correctamente
aws cloudformation describe-stacks --stack-name eks-mcp-permissions
aws cloudformation describe-stacks --stack-name eks-mcp-additional-permissions
```

**⚠️ Advertencia**: Solo elimina el stack de permisos si estás seguro de que no lo necesitarás para otros proyectos con EKS MCP.

---

## Referencias adicionales

- [EKS MCP Server Documentation](https://awslabs.github.io/mcp/servers/eks-mcp-server/)
- [Amazon Q Developer CLI](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Spring Boot 3.x Migration Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide)

---

**💡 Tip**: Usa lenguaje natural específico y detallado cuando interactúes con Amazon Q Developer. Mientras más contexto proporciones sobre lo que necesitas, mejor será la asistencia que recibirás.
