#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
source ./config.sh

if $AWS s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "bucket ja existe: $BUCKET"
else
  $AWS s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGIAO" >/dev/null
  echo "bucket criado: $BUCKET"
fi
