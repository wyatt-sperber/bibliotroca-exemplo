#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
source ./config.sh

URL_API=$(cat .url-api)

if $AWS s3api head-bucket \
     --bucket "$BUCKET_SITE" 2>/dev/null; then
  echo "bucket do site ja existe"
else
  $AWS s3api create-bucket \
    --bucket "$BUCKET_SITE" \
    --region "$REGIAO" >/dev/null
  echo "bucket do site criado"
fi

$AWS s3 website "s3://${BUCKET_SITE}" \
  --index-document index.html

POLITICA='{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::NOME_BUCKET/*"
  }]
}'
POLITICA="${POLITICA//NOME_BUCKET/$BUCKET_SITE}"

$AWS s3api put-bucket-policy \
  --bucket "$BUCKET_SITE" \
  --policy "$POLITICA"

echo "const URL_API = \"${URL_API}\";" \
  > ../app/site/config.js

$AWS s3 cp ../app/site/ "s3://${BUCKET_SITE}/" \
  --recursive >/dev/null

DOMINIO="s3-website.localhost.localstack.cloud:4566"
echo
echo "site publicado em:"
echo "http://${BUCKET_SITE}.${DOMINIO}"
