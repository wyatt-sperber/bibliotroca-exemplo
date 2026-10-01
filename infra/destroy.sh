#!/usr/bin/env bash
cd "$(dirname "$0")"
source ./config.sh

if [ -f .id-api ]; then
  $AWS apigateway delete-rest-api \
    --rest-api-id "$(cat .id-api)" 2>/dev/null || true
fi

$AWS lambda delete-function \
  --function-name "$FUNCAO_CONSULTAR" 2>/dev/null || true
$AWS lambda delete-function \
  --function-name "$FUNCAO_GRAVAR" 2>/dev/null || true
$AWS iam delete-role-policy --role-name "$PAPEL" \
  --policy-name "${PREFIXO}-politica" 2>/dev/null || true
$AWS iam delete-role \
  --role-name "$PAPEL" 2>/dev/null || true
$AWS dynamodb delete-table \
  --table-name "$TABELA" 2>/dev/null || true
$AWS s3 rb "s3://$BUCKET" --force 2>/dev/null || true
$AWS s3 rb "s3://$BUCKET_SITE" --force 2>/dev/null || true

rm -f .id-api .url-api openapi-pronto.yaml
rm -f ../app/site/config.js

echo "recursos removidos"
