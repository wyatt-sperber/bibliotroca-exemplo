"""Marca um livro como trocado.  RF-04.

Esta função NÃO está no roteiro. Ela existe porque o documento de
requisitos da Sprint 1 declarou o RF-04 e a história US-03, e um
requisito declarado que ninguém implementa aparece como buraco na
matriz de rastreabilidade da Sprint 5.

Ela também serve de modelo para a pergunta que mais aparece: "e se o
meu projeto precisar de uma terceira função?". Precisa de quatro
coisas, e nenhuma é nova:

  1. uma pasta em `app/` com um `handler.py`;
  2. um script `infra/08-funcao-marcar.sh`, igual ao 04 e ao 05
     trocando o nome;
  3. uma rota no `infra/openapi.yaml` apontando para ela;
  4. uma linha no `infra/deploy.sh`.

Repare que não há `update_item` aqui. O item é lido pelo `query` da
partição e regravado inteiro com `put_item`, que é o mesmo comando que
a Sprint 3 já ensinou. Em uma tabela com chave composta, regravar a
mesma chave substitui o item — e assim esta função não introduz nenhum
comando novo em relação ao que já foi visto.
"""
import json
import os

import boto3
from boto3.dynamodb.conditions import Key

TABELA = os.environ["TABELA"]

dynamodb = boto3.resource("dynamodb")
tabela = dynamodb.Table(TABELA)

CAMPOS_OBRIGATORIOS = ["bairro", "id_livro"]


def resposta(codigo, corpo):
    return {
        "statusCode": codigo,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(corpo, ensure_ascii=False),
    }


def lambda_handler(event, context):
    try:
        dados = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return resposta(400, {"erro": "corpo nao e JSON valido"})

    faltando = [c for c in CAMPOS_OBRIGATORIOS if not dados.get(c)]
    if faltando:
        return resposta(400, {
            "erro": "campos obrigatorios ausentes",
            "campos": faltando,
        })

    bairro = str(dados["bairro"]).strip()
    id_livro = str(dados["id_livro"]).strip()

    resultado = tabela.query(KeyConditionExpression=Key("bairro").eq(bairro))
    alvo = next((i for i in resultado.get("Items", [])
                 if i.get("id_livro") == id_livro), None)

    # US-03, cenário 2: identificador inexistente não altera nada
    if alvo is None:
        print("livro nao encontrado bairro={} id={}".format(bairro, id_livro))
        return resposta(404, {"erro": "livro nao encontrado"})

    if alvo.get("disponivel") == "nao":
        return resposta(200, {
            "id_livro": id_livro,
            "disponivel": "nao",
            "observacao": "o livro ja estava marcado como trocado",
        })

    alvo["disponivel"] = "nao"
    tabela.put_item(Item=alvo)

    print("marcado como trocado bairro={} id={}".format(bairro, id_livro))

    return resposta(200, {"id_livro": id_livro, "disponivel": "nao"})
