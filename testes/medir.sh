#!/usr/bin/env bash
# Mede o tempo de resposta da rota de consulta.
cd "$(dirname "$0")"

URL=$(cat ../infra/.url-api)
ALVO="$URL/livros?bairro=Tijuca"
AMOSTRAS=30

# Aquecimento: a primeira execucao inclui a partida
# da funcao, que nao representa o regime normal.
curl -s -o /dev/null "$ALVO"

for _ in $(seq 1 "$AMOSTRAS"); do
  curl -s -o /dev/null -w "%{time_total}\n" "$ALVO"
done | sort -n > tempos.txt

TOTAL=$(wc -l < tempos.txt)
INDICE=$(( (TOTAL * 95 + 99) / 100 ))

echo "amostras:    $TOTAL"
echo "minimo (s):  $(head -1 tempos.txt)"
echo "mediana (s): $(sed -n "$((TOTAL / 2))p" tempos.txt)"
echo "p95 (s):     $(sed -n "${INDICE}p" tempos.txt)"
echo "maximo (s):  $(tail -1 tempos.txt)"
