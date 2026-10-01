#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

./01-bucket.sh
./02-tabela.sh
./03-papel.sh
./04-funcao-gravar.sh

echo
echo "ambiente criado"
