#!/usr/bin/env bash
# Executa os seis criterios de aceite declarados na Sprint 1.
# Cada bloco abaixo e a traducao literal de um "Dado / Quando / Entao"
# do documento docs/01-requisitos.md.
cd "$(dirname "$0")"
source ../infra/config.sh

URL=$(cat ../infra/.url-api)
PASSOU=0
FALHOU=0

verificar() {
  local nome="$1" esperado="$2" obtido="$3"
  if [ "$esperado" = "$obtido" ]; then
    echo "OK     $nome"
    PASSOU=$((PASSOU + 1))
  else
    echo "FALHA  $nome"
    echo "       esperado: $esperado"
    echo "       obtido:   $obtido"
    FALHOU=$((FALHOU + 1))
  fi
}

postar() {           # postar <rota> <corpo>   -> corpo da resposta
  curl -s -X POST "$URL$1" \
    -H 'Content-Type: application/json' -d "$2"
}

codigo_post() {      # codigo_post <rota> <corpo>  -> codigo HTTP
  curl -s -o /dev/null -w "%{http_code}" -X POST "$URL$1" \
    -H 'Content-Type: application/json' -d "$2"
}

campo() {            # campo <json> <nome>  -> valor da chave
  printf '%s' "$1" \
    | sed -n 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

total() {
  curl -s "$1" \
    | sed -n 's/.*"total"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p'
}

titulos_em_ordem() {  # os titulos da consulta, na ordem devolvida
  curl -s "$1" \
    | grep -o '"titulo"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | sed 's/.*"\([^"]*\)"$/\1/' \
    | paste -sd'|' -
}

BAIRRO="teste-$(date +%s)-$$"
VAZIO="bairro-sem-livros-$$"
# um JPEG minimo valido, em base64, para servir de foto da capa
CAPA="/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsL"
CAPA="${CAPA}DBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4z"
CAPA="${CAPA}NDL/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAA"
CAPA="${CAPA}AAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q=="

echo "bairro de teste: $BAIRRO"
echo

# ─────────────────────────────────────────────── US-01, cenario 1
# Dado que preencho titulo, autor, bairro e estado, e anexo uma foto
# Quando confirmo o cadastro
# Entao o sistema devolve um identificador e a foto fica acessivel
# pelo endereco devolvido
COMPLETO="{\"bairro\":\"$BAIRRO\",\"titulo\":\"Grande Sertao Veredas\","
COMPLETO="$COMPLETO\"autor\":\"Guimaraes Rosa\",\"estado\":\"bom\","
COMPLETO="$COMPLETO\"capa_base64\":\"$CAPA\"}"

RESPOSTA=$(postar /livros "$COMPLETO")
ID_1=$(campo "$RESPOSTA" id_livro)
CHAVE_CAPA=$(campo "$RESPOSTA" capa)

verificar "C1a cadastro completo devolve identificador" "sim" \
  "$([ -n "$ID_1" ] && echo sim || echo nao)"

verificar "C1b a foto esta no S3 no endereco devolvido" "sim" \
  "$($AWS s3api head-object --bucket "$BUCKET" --key "$CHAVE_CAPA" \
      >/dev/null 2>&1 && echo sim || echo nao)"

# ─────────────────────────────────────────────── US-01, cenario 2
# Dado que deixo o campo bairro em branco
# Quando confirmo o cadastro
# Entao o sistema recusa, informa que o bairro e obrigatorio, e
# nenhum livro e criado
SEM_BAIRRO='{"bairro":"","titulo":"Sem bairro",'
SEM_BAIRRO="$SEM_BAIRRO\"autor\":\"Alguem\",\"estado\":\"bom\"}"
RECUSA=$(postar /livros "$SEM_BAIRRO")

verificar "C2a cadastro sem bairro devolve 400" "400" \
  "$(codigo_post /livros "$SEM_BAIRRO")"
verificar "C2b a recusa diz qual campo faltou" "sim" \
  "$(printf '%s' "$RECUSA" | grep -q 'bairro' && echo sim || echo nao)"

# ─────────────────────────────────────────────── US-02, cenario 1
# Dado que o bairro tem 3 livros disponiveis e 1 ja trocado
# Quando consulto os livros do bairro
# Entao a lista traz exatamente 3, do mais recente para o mais antigo
for PAR in "Dom Casmurro|Machado de Assis" \
           "Vidas Secas|Graciliano Ramos" \
           "A Hora da Estrela|Clarice Lispector"; do
  sleep 1          # um segundo entre os cadastros, para a ordem existir
  T="${PAR%%|*}"; A="${PAR##*|}"
  CORPO="{\"bairro\":\"$BAIRRO\",\"titulo\":\"$T\",\"autor\":\"$A\","
  CORPO="$CORPO\"estado\":\"bom\"}"
  postar /livros "$CORPO" >/dev/null
done

# o primeiro livro cadastrado e o que sera marcado como trocado
postar /livros/trocado \
  "{\"bairro\":\"$BAIRRO\",\"id_livro\":\"$ID_1\"}" >/dev/null

verificar "C3a o bairro com 1 trocado lista exatamente 3" "3" \
  "$(total "$URL/livros?bairro=$BAIRRO")"
verificar "C3b a lista vem do mais recente para o mais antigo" \
  "A Hora da Estrela|Vidas Secas|Dom Casmurro" \
  "$(titulos_em_ordem "$URL/livros?bairro=$BAIRRO")"

# ─────────────────────────────────────────────── US-02, cenario 2
# Dado que o bairro nao tem nenhum livro cadastrado
# Quando consulto os livros desse bairro
# Entao a resposta informa que nao ha livros, com total zero
verificar "C4 bairro sem livros devolve total zero" "0" \
  "$(total "$URL/livros?bairro=$VAZIO")"

# ─────────────────────────────────────────────── US-03, cenario 1
# Dado que sou dono de um livro disponivel
# Quando marco o livro como trocado
# Entao ele deixa de aparecer na consulta seguinte
ALVO=$(postar /livros \
  "{\"bairro\":\"$BAIRRO\",\"titulo\":\"Livro a trocar\",\
\"autor\":\"Autor\",\"estado\":\"novo\"}")
ID_ALVO=$(campo "$ALVO" id_livro)
ANTES=$(total "$URL/livros?bairro=$BAIRRO")
postar /livros/trocado \
  "{\"bairro\":\"$BAIRRO\",\"id_livro\":\"$ID_ALVO\"}" >/dev/null
DEPOIS=$(total "$URL/livros?bairro=$BAIRRO")

verificar "C5 marcar como trocado tira o livro da consulta" \
  "$((ANTES - 1))" "$DEPOIS"

# ─────────────────────────────────────────────── US-03, cenario 2
# Dado que informo um identificador que nao existe
# Quando tento marca-lo como trocado
# Entao o sistema informa que nao foi encontrado e nenhum outro
# registro e alterado
verificar "C6a identificador inexistente devolve 404" "404" \
  "$(codigo_post /livros/trocado \
     "{\"bairro\":\"$BAIRRO\",\"id_livro\":\"nao-existe-999\"}")"
verificar "C6b nenhum outro registro foi alterado" "$DEPOIS" \
  "$(total "$URL/livros?bairro=$BAIRRO")"

echo
echo "passaram: $PASSOU   falharam: $FALHOU"
[ "$FALHOU" -eq 0 ]
