#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

./01-bucket.sh
./02-tabela.sh
./03-papel.sh
./04-funcao-gravar.sh
./05-funcao-consultar.sh
./08-funcao-marcar.sh
./06-api.sh
./07-site.sh

echo
echo "aplicacao no ar"
