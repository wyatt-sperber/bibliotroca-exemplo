"""Grava um livro disponível para troca.  RF-01, RF-02, RF-05.

Esta é a função da Sprint 3, adaptada ao cenário BiblioTroca.

Em relação ao código genérico do roteiro mudaram duas coisas, e só:

1. Os nomes dos campos. O roteiro usa `id_particao`, `descricao` e
   `valor`, que são genéricos de propósito. Aqui viraram `bairro`,
   `titulo`, `autor` e `estado`, que é o que o RF-01 manda registrar.
   A chave de partição continua sendo a mesma ideia: o campo pelo qual
   a consulta da Sprint 4 vai buscar.

2. A foto da capa. O RF-02 promete que a foto enviada no cadastro é
   guardada no Amazon S3. O roteiro guarda no S3 a ficha do registro em
   JSON; aqui guardamos as duas coisas, a ficha e a imagem. Sem isso o
   RF-02 apareceria como não cumprido na matriz de rastreabilidade da
   Sprint 5, e esse é justamente o tipo de buraco que a matriz existe
   para encontrar.
"""
import base64
import binascii
import json
import os
import uuid
from datetime import datetime, timezone

import boto3

TABELA = os.environ["TABELA"]
BUCKET = os.environ["BUCKET"]

dynamodb = boto3.resource("dynamodb")
s3 = boto3.client("s3")
tabela = dynamodb.Table(TABELA)

# RF-05 cita título e bairro. Autor e estado entram junto porque o
# RF-01 manda registrar os quatro.
CAMPOS_OBRIGATORIOS = ["bairro", "titulo", "autor", "estado"]

ESTADOS = ["novo", "bom", "gasto"]
LIMITE_FOTO_BYTES = 2 * 1024 * 1024


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

    # RF-05: recusa e diz qual campo faltou
    faltando = [c for c in CAMPOS_OBRIGATORIOS if not dados.get(c)]
    if faltando:
        return resposta(400, {
            "erro": "campos obrigatorios ausentes",
            "campos": faltando,
        })

    estado = str(dados["estado"]).strip().lower()
    if estado not in ESTADOS:
        return resposta(400, {
            "erro": "estado de conservacao invalido",
            "aceitos": ESTADOS,
        })

    agora = datetime.now(timezone.utc).isoformat()
    registro = {
        "bairro": str(dados["bairro"]).strip(),
        "id_livro": str(uuid.uuid4()),
        "titulo": str(dados["titulo"]).strip(),
        "autor": str(dados["autor"]).strip(),
        "estado": estado,
        "disponivel": "sim",
        "criado_em": agora,
    }

    # RF-02: a foto vai para o S3 antes de o livro existir na tabela.
    # A ordem não é estética: é o requisito de Reliability do FURPS —
    # não pode sobrar um livro listado apontando para uma imagem que
    # nunca subiu.
    capa = dados.get("capa_base64")
    chave_capa = None
    if capa:
        try:
            imagem = base64.b64decode(capa, validate=True)
        except (binascii.Error, ValueError):
            return resposta(400, {"erro": "capa_base64 nao e base64 valido"})
        if len(imagem) > LIMITE_FOTO_BYTES:
            return resposta(413, {
                "erro": "capa maior que o limite",
                "limite_bytes": LIMITE_FOTO_BYTES,
            })
        chave_capa = "capas/{}/{}.jpg".format(
            registro["bairro"], registro["id_livro"]
        )
        s3.put_object(
            Bucket=BUCKET,
            Key=chave_capa,
            Body=imagem,
            ContentType="image/jpeg",
        )
        registro["capa"] = chave_capa

    tabela.put_item(Item=registro)

    chave_ficha = "fichas/{}/{}.json".format(
        registro["bairro"], registro["id_livro"]
    )
    s3.put_object(
        Bucket=BUCKET,
        Key=chave_ficha,
        Body=json.dumps(registro, ensure_ascii=False).encode(),
        ContentType="application/json",
    )

    print("gravado id={} bairro={} capa={}".format(
        registro["id_livro"], registro["bairro"], bool(chave_capa)
    ))

    return resposta(201, {
        "id_livro": registro["id_livro"],
        "ficha": chave_ficha,
        "capa": chave_capa,
    })
