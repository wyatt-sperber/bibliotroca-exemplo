#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
source ./config.sh

CONTA=$($AWS sts get-caller-identity \
  --query Account --output text)
ARN_PAPEL="arn:aws:iam::${CONTA}:role/${PAPEL}"

PASTA="../app/gravar"
empacotar "$PASTA" "$PASTA/funcao.zip"
PACOTE="fileb://${PASTA}/funcao.zip"

VARIAVEIS="Variables={TABELA=$TABELA,BUCKET=$BUCKET}"

if $AWS lambda get-function \
     --function-name "$FUNCAO_GRAVAR" >/dev/null 2>&1; then
  $AWS lambda update-function-code \
    --function-name "$FUNCAO_GRAVAR" \
    --zip-file "$PACOTE" >/dev/null
  $AWS lambda wait function-updated \
    --function-name "$FUNCAO_GRAVAR"
  $AWS lambda update-function-configuration \
    --function-name "$FUNCAO_GRAVAR" \
    --environment "$VARIAVEIS" >/dev/null
  echo "funcao atualizada: $FUNCAO_GRAVAR"
else
  $AWS lambda create-function \
    --function-name "$FUNCAO_GRAVAR" \
    --runtime python3.12 \
    --handler handler.lambda_handler \
    --role "$ARN_PAPEL" \
    --zip-file "$PACOTE" \
    --timeout 15 \
    --environment "$VARIAVEIS" >/dev/null
  echo "funcao criada: $FUNCAO_GRAVAR"
fi

$AWS lambda wait function-updated \
  --function-name "$FUNCAO_GRAVAR"
echo "funcao pronta"
