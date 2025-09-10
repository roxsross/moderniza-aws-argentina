#!/bin/bash

# Script para desplegar ambos stacks de permisos IAM para EKS MCP
set -e

# Configuración de stacks
MAIN_STACK_NAME="eks-mcp-permissions"
ADDITIONAL_STACK_NAME="eks-mcp-additional-permissions"
MAIN_TEMPLATE="cloudformation.yaml"
ADDITIONAL_TEMPLATE="cloudformation-additional.yaml"

echo "🚀 Desplegando permisos IAM completos para EKS MCP..."

# Verificar que los templates existen
if [ ! -f "$MAIN_TEMPLATE" ]; then
    echo "❌ No se encuentra el archivo $MAIN_TEMPLATE"
    exit 1
fi

if [ ! -f "$ADDITIONAL_TEMPLATE" ]; then
    echo "❌ No se encuentra el archivo $ADDITIONAL_TEMPLATE"
    exit 1
fi

# Desplegar stack principal
echo "📝 1/2 - Creando stack principal de permisos..."
aws cloudformation create-stack \
    --stack-name "$MAIN_STACK_NAME" \
    --template-body "file://$MAIN_TEMPLATE" \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameters ParameterKey=PolicyName,ParameterValue=AmazonQDeveloperEKSMCPPolicy

echo "⏳ Esperando completar stack principal..."
aws cloudformation wait stack-create-complete --stack-name "$MAIN_STACK_NAME"

if [ $? -ne 0 ]; then
    echo "❌ Error creando el stack principal"
    exit 1
fi

echo "✅ Stack principal creado exitosamente!"

# Desplegar stack adicional
echo "📝 2/2 - Creando stack de permisos adicionales..."
aws cloudformation create-stack \
    --stack-name "$ADDITIONAL_STACK_NAME" \
    --template-body "file://$ADDITIONAL_TEMPLATE" \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameters ParameterKey=PolicyName,ParameterValue=AmazonQDeveloperEKSMCPAdditionalPolicy

echo "⏳ Esperando completar stack adicional..."
aws cloudformation wait stack-create-complete --stack-name "$ADDITIONAL_STACK_NAME"

if [ $? -ne 0 ]; then
    echo "❌ Error creando el stack adicional"
    exit 1
fi

echo "✅ Stack adicional creado exitosamente!"

# Obtener ARNs de las policies
echo ""
echo "🎉 Ambos stacks desplegados exitosamente!"
echo ""
echo "📋 Policies creadas:"

MAIN_POLICY_ARN=$(aws cloudformation describe-stacks \
    --stack-name "$MAIN_STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`PolicyArn`].OutputValue' \
    --output text)

ADDITIONAL_POLICY_ARN=$(aws cloudformation describe-stacks \
    --stack-name "$ADDITIONAL_STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`AdditionalPolicyArn`].OutputValue' \
    --output text)

echo "   1. Policy Principal: $MAIN_POLICY_ARN"
echo "   2. Policy Adicional: $ADDITIONAL_POLICY_ARN"
echo ""
echo "🔧 Próximo paso:"
echo "   Asocia AMBAS policies a tu Permission Set de SSO para tener permisos completos"
echo "   para crear y gestionar clusters EKS con Node Groups."
echo ""
echo "🚀 Una vez asociadas, puedes crear el cluster EKS."
