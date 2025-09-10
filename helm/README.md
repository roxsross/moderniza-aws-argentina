# Helm Chart para Spring PetClinic

Este directorio contiene el Helm Chart para desplegar la aplicación Spring PetClinic modernizada en Amazon EKS.

## Estructura del Chart

```
helm/
├── spring-petclinic/
│   ├── Chart.yaml              # Metadatos del chart
│   ├── values.yaml             # Valores por defecto
│   └── templates/
│       ├── deployment.yaml     # Deployment de la aplicación
│       ├── service.yaml        # Service LoadBalancer
│       ├── namespace.yaml      # Namespace petclinic
│       └── _helpers.tpl        # Templates helper
├── deploy-app.sh               # Script de despliegue
└── README.md                   # Este archivo
```

## Características del Chart

- **Réplicas:** 2 por defecto (configurable)
- **Puerto:** 8080 (Spring Boot)
- **Service:** LoadBalancer (AWS NLB)
- **Health Checks:** Spring Boot Actuator
- **Namespace:** petclinic
- **Recursos:** CPU/Memory limits configurados

## Uso rápido

```bash
# 1. Construir y subir imagen a ECR (ejemplo)
aws ecr create-repository --repository-name spring-petclinic
docker build -t spring-petclinic .
docker tag spring-petclinic:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/spring-petclinic:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/spring-petclinic:latest

# 2. Desplegar con el script
./helm/deploy-app.sh 123456789012.dkr.ecr.us-east-1.amazonaws.com/spring-petclinic:latest
```

## Uso manual con Helm

```bash
# Instalar/actualizar
helm upgrade --install petclinic-app ./helm/spring-petclinic \
    --namespace petclinic \
    --set image.repository=123456789012.dkr.ecr.us-east-1.amazonaws.com/spring-petclinic \
    --set image.tag=latest \
    --create-namespace

# Ver status
helm status petclinic-app -n petclinic

# Desinstalar
helm uninstall petclinic-app -n petclinic
```

## Configuración personalizada

Puedes personalizar el despliegue modificando `values.yaml` o usando `--set`:

```bash
# Cambiar número de réplicas
--set replicaCount=3

# Cambiar recursos
--set resources.requests.memory=512Mi

# Deshabilitar health checks
--set healthcheck.enabled=false
```

## Health Checks

El chart incluye health checks para Spring Boot Actuator:

- **Liveness Probe:** `/actuator/health/liveness`
- **Readiness Probe:** `/actuator/health/readiness`

Asegúrate de que tu aplicación Spring Boot tenga habilitado Actuator.

## Troubleshooting

### Pods no inician
```bash
kubectl describe pods -n petclinic
kubectl logs -f deployment/petclinic-app -n petclinic
```

### LoadBalancer sin IP externa
```bash
kubectl get svc -n petclinic
kubectl describe svc petclinic-app -n petclinic
```

### Health checks fallan
Verifica que los endpoints de Actuator estén disponibles:
```bash
kubectl port-forward svc/petclinic-app 8080:80 -n petclinic
curl http://localhost:8080/actuator/health
```
