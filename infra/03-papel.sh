#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
source ./config.sh

CONFIANCA='{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "lambda.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}'

if $AWS iam get-role --role-name "$PAPEL" >/dev/null 2>&1; then
  echo "papel ja existe: $PAPEL"
else
  $AWS iam create-role \
    --role-name "$PAPEL" \
    --assume-role-policy-document "$CONFIANCA" >/dev/null
  echo "papel criado: $PAPEL"
fi

# O roteiro usa "Resource": "*" em toda a politica, para nao exigir o
# numero da conta antes da hora. Aqui a politica aponta para a tabela e
# para o bucket deste projeto, e so para eles — que e o que o RNF-02 do
# documento de arquitetura promete. Com "*", a promessa de menor
# privilegio nao se sustentaria na hora de preencher a matriz.
CONTA=$($AWS sts get-caller-identity --query Account --output text)
ARN_TABELA="arn:aws:dynamodb:${REGIAO}:${CONTA}:table/${TABELA}"

PERMISSOES='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:GetItem"
      ],
      "Resource": "ARN_TABELA"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject"],
      "Resource": "arn:aws:s3:::NOME_BUCKET/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}'
# O grupo de registros nasce com o nome da funcao, que a AWS so define
# quando a funcao e criada. Por isso o terceiro bloco continua em "*":
# restringir aqui exigiria criar a funcao antes do papel, e o papel e
# pre-requisito da funcao.
PERMISSOES="${PERMISSOES//ARN_TABELA/$ARN_TABELA}"
PERMISSOES="${PERMISSOES//NOME_BUCKET/$BUCKET}"

$AWS iam put-role-policy \
  --role-name "$PAPEL" \
  --policy-name "${PREFIXO}-politica" \
  --policy-document "$PERMISSOES"

echo "politica anexada ao papel $PAPEL"
