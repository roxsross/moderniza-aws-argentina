# Moderniza AWS Argentina 🇦🇷

Repositorio demo para la sesión **“Moderniza y despliega en AWS con MCP y Amazon Q”** en el **AWS Community Day Argentina**.

Este proyecto muestra cómo dar nueva vida a aplicaciones heredadas utilizando:
- ✨ **Amazon Q Developer CLI** para asistir en la modernización del código.
- 📦 **MCP (Modernization Containerization Platform)** para contenedorización rápida y segura.
- 🚀 **Amazon EKS** para desplegar aplicaciones listas para escalar en la nube.

La aplicación base es el clásico **Spring Petclinic**, modernizado y preparado para correr en AWS.

---

## 🛠️ Prerrequisitos

- [Docker](https://docs.docker.com/get-docker/) instalado
- [AWS CLI](https://docs.aws.amazon.com/cli/) configurado
- [kubectl](https://kubernetes.io/docs/tasks/tools/) instalado
- [Amazon Q Developer CLI](https://aws.amazon.com/q/developer/) habilitado
- Acceso a un cluster de **Amazon EKS** o [eksctl](https://eksctl.io/) para crear uno

---

## 🚀 Pasos rápidos

### 1. Clonar el repo
```bash
git clone https://github.com/roxsross/moderniza-aws-argentina.git
cd moderniza-aws-argentina
````



## 🎯 Objetivo

Que cualquier desarrollador pueda:

1. Tomar una app **legacy** (Spring Petclinic).
2. Modernizarla con ayuda de **Amazon Q**.
3. Empaquetarla en un contenedor usando **MCP**.
4. Desplegarla en **Amazon EKS** con un flujo asistido por IA.

---

## 🙌 Créditos

Basado en [dockersamples/spring-petclinic-docker](https://github.com/dockersamples/spring-petclinic-docker).
Adaptado para **AWS Community Day Argentina**.

## 👩‍💻 Authors / Speakers

- Rossana Suarez (@roxsross) – AWS Container Hero, Tech Lead DevOps

- Matías Anoniz – Solutions Architect, AWS
