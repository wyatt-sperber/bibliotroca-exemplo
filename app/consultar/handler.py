"""Lista os livros disponíveis de um bairro.  RF-03.

Esta é a função da Sprint 4, adaptada ao cenário BiblioTroca.

Duas diferenças em relação ao código genérico do roteiro:

1. O nome da chave. Onde o roteiro escreve `id_particao`, aqui está
   `bairro`. A operação é a mesma, e é a que importa: `query`, e não
   `scan`. O `query` vai direto na partição; o `scan` leria a tabela
   inteira e cresceria junto com ela. É a decisão que o RNF-01 do
   documento de arquitetura justifica com número.

2. O RF-03 pede duas coisas que o roteiro genérico não pede: só os
   disponíveis, e do mais recente para o mais antigo. As duas são
   resolvidas aqui, em Python, depois do `query`. Em um catálogo de
   bairro isso custa nada, porque a partição é pequena por construção.
   Se um bairro passasse de alguns milhares de livros, a decisão certa
   seria um índice secundário — e isso está declarado na seção de
   limites do documento de arquitetura.
"""
import json
import os

import boto3
from boto3.dynamodb.conditions import Key

TABELA = os.environ["TABELA"]

dynamodb = boto3.resource("dynamodb")
tabela = dynamodb.Table(TABELA)

LIMITE_PADRAO = 20
LIMITE_MAXIMO = 100


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
    parametros = event.get("queryStringParameters") or {}
    bairro = parametros.get("bairro")

    if not bairro:
        return resposta(400, {"erro": "parametro bairro e obrigatorio"})

    try:
        limite = int(parametros.get("limite", LIMITE_PADRAO))
    except ValueError:
        return resposta(400, {"erro": "limite nao e numerico"})

    limite = max(1, min(limite, LIMITE_MAXIMO))

    resultado = tabela.query(
        KeyConditionExpression=Key("bairro").eq(bairro)
    )
    itens = resultado.get("Items", [])

    # RF-03: só os disponíveis
    itens = [i for i in itens if i.get("disponivel", "sim") == "sim"]
    # RF-03: do cadastro mais recente para o mais antigo
    itens.sort(key=lambda i: i.get("criado_em", ""), reverse=True)
    itens = itens[:limite]

    print("consulta bairro={} itens={}".format(bairro, len(itens)))

    return resposta(200, {"total": len(itens), "itens": itens})
