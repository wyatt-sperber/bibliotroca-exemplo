#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
source ./config.sh

if $AWS dynamodb describe-table \
     --table-name "$TABELA" >/dev/null 2>&1; then
  echo "tabela ja existe: $TABELA"
  exit 0
fi

$AWS dynamodb create-table \
  --table-name "$TABELA" \
  --attribute-definitions \
      AttributeName=bairro,AttributeType=S \
      AttributeName=id_livro,AttributeType=S \
  --key-schema \
      AttributeName=bairro,KeyType=HASH \
      AttributeName=id_livro,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST >/dev/null

$AWS dynamodb wait table-exists --table-name "$TABELA"
echo "tabela criada: $TABELA"
