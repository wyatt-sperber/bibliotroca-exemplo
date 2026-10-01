#!/usr/bin/env bash
# Nomes dos recursos do projeto.
# Troque o prefixo pelo nome do seu projeto.

PREFIXO="bibliotroca"
REGIAO="us-east-1"

BUCKET="${PREFIXO}-capas"
TABELA="${PREFIXO}-livros"
PAPEL="${PREFIXO}-papel-lambda"
FUNCAO_GRAVAR="${PREFIXO}-gravar"
FUNCAO_MARCAR="${PREFIXO}-marcar"

# Forma de enviar comandos ao emulador.
# Se você escolheu a forma 2 ou 3 na Sprint 0,
# troque esta linha pela que você usa.
AWS="lstk aws"

# Empacota uma pasta em um .zip, com o que a máquina tiver.
# Uso: empacotar <pasta> <arquivo.zip>
empacotar() {
  local pasta="$1"
  local destino="$2"
  local base="${TMPDIR:-/tmp}/pacote-$$"
  rm -rf "$base" "$base.zip"
  mkdir -p "$base"
  cp -r "$pasta"/. "$base"/
  rm -rf "$base/__pycache__" "$base"/*.zip
  if command -v zip >/dev/null 2>&1; then
    ( cd "$base" && zip -qr "$base.zip" . )
  elif command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command "Compress-Archive \
      -Path '$(cygpath -w "$base")\*' \
      -DestinationPath '$(cygpath -w "$base.zip")' -Force"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import shutil,sys
shutil.make_archive(sys.argv[1], 'zip', sys.argv[2])" "$base" "$base"
  else
    echo "sem zip, powershell ou python para empacotar" >&2
    return 1
  fi
  rm -f "$destino"
  mv "$base.zip" "$destino"
  rm -rf "$base"
}

FUNCAO_CONSULTAR="${PREFIXO}-consultar"
API_NOME="${PREFIXO}-api"
ESTAGIO="dev"
BUCKET_SITE="${PREFIXO}-site"
