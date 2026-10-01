#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
source ./config.sh

CONTA=$($AWS sts get-caller-identity \
  --query Account --output text)

ARN_GRAVAR=$($AWS lambda get-function \
  --function-name "$FUNCAO_GRAVAR" \
  --query "Configuration.FunctionArn" --output text)
ARN_CONSULTAR=$($AWS lambda get-function \
  --function-name "$FUNCAO_CONSULTAR" \
  --query "Configuration.FunctionArn" --output text)
ARN_MARCAR=$($AWS lambda get-function \
  --function-name "$FUNCAO_MARCAR" \
  --query "Configuration.FunctionArn" --output text)

BASE="arn:aws:apigateway:${REGIAO}:lambda:path"
SUFIXO="invocations"
URI_GRAVAR="${BASE}/2015-03-31/functions/${ARN_GRAVAR}/${SUFIXO}"
URI_CONSULTAR="${BASE}/2015-03-31/functions"
URI_CONSULTAR="${URI_CONSULTAR}/${ARN_CONSULTAR}/${SUFIXO}"
URI_MARCAR="${BASE}/2015-03-31/functions/${ARN_MARCAR}/${SUFIXO}"

sed -e "s|API_NOME|${API_NOME}|" \
    -e "s|URI_GRAVAR|${URI_GRAVAR}|" \
    -e "s|URI_CONSULTAR|${URI_CONSULTAR}|" \
    -e "s|URI_MARCAR|${URI_MARCAR}|" \
    openapi.yaml > openapi-pronto.yaml

ID_API=$($AWS apigateway get-rest-apis \
  --query "items[?name=='${API_NOME}'].id | [0]" \
  --output text)

if [ -z "$ID_API" ] || [ "$ID_API" = "None" ]; then
  ID_API=$($AWS apigateway import-rest-api \
    --body fileb://openapi-pronto.yaml \
    --query "id" --output text)
  echo "api criada: $ID_API"
else
  $AWS apigateway put-rest-api \
    --rest-api-id "$ID_API" \
    --mode overwrite \
    --body fileb://openapi-pronto.yaml >/dev/null
  echo "api atualizada: $ID_API"
fi

ORIGEM="arn:aws:execute-api:${REGIAO}:${CONTA}:${ID_API}/*/*"

for FUNCAO in "$FUNCAO_GRAVAR" "$FUNCAO_CONSULTAR" \
              "$FUNCAO_MARCAR"; do
  $AWS lambda add-permission \
    --function-name "$FUNCAO" \
    --statement-id "apigw-${ID_API}" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "$ORIGEM" >/dev/null 2>&1 || true
done

$AWS apigateway create-deployment \
  --rest-api-id "$ID_API" \
  --stage-name "$ESTAGIO" >/dev/null

DOMINIO="execute-api.localhost.localstack.cloud:4566"
URL="http://${ID_API}.${DOMINIO}/${ESTAGIO}"

echo "$ID_API" > .id-api
echo "$URL" > .url-api

echo "api publicada em: $URL"
