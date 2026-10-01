> **Você está na branch `sprint-2`.** Ela está congelada no estado em
> que o projeto deveria estar ao final daquela sprint: aqui existe só o
> que já tinha sido feito até ali. O estado final do projeto está na
> branch `main`.

# BiblioTroca

Catálogo de livros que moradores de um bairro disponibilizam para troca
entre si.

Este é o **projeto-exemplo** de *Projeto em Ciência de Dados IV*
(IBM8942). Ele existe para que vocês possam ver, rodando, tudo que o
roteiro pede — a documentação de cada sprint, os scripts, o código das
funções, os testes e as medições. O cenário **não é nenhum dos dois
oficiais**, de propósito: aqui está a forma, não o conteúdo. Se o
projeto da sua equipe sair parecido com este no conteúdo, alguma coisa
deu errado.

## O que tem em cada branch

Cada branch está congelada no estado em que o projeto deveria estar ao
final daquela sprint. Troque de branch para ver o projeto crescendo.

| Branch | O que existe nela |
|---|---|
| `sprint-1` | `docs/01-requisitos.md` e a estrutura de pastas. Nenhuma linha de código. |
| `sprint-2` | `+ docs/02-arquitetura.md` e `docs/diagrama.md`. Ainda nenhuma linha de código. |
| `sprint-3` | `+ infra/` até a função `gravar`, e `app/gravar/`. O ambiente sobe por script. |
| `sprint-4` | `+ app/consultar/`, `app/marcar/`, a API, o site. A aplicação no ar. |
| `sprint-5` | `+ testes/` e `docs/03-validacao.md`. O que foi prometido, medido. |
| `main` | O estado final, igual à `sprint-5`. |

```
git switch sprint-3        # ver o projeto como ele estava ali
git switch main            # voltar ao estado final
```

## Antes de rodar

**1. O emulador precisa estar de pé.** Esta é a primeira linha porque
foi o primeiro erro de quem tentou rodar sem saber:

```
lstk status
```

Se não disser que está rodando, suba com `lstk start` e espere. A
primeira vez é lenta, porque baixa a imagem — pode passar de um minuto
sem imprimir nada. Não interrompa: interromper na metade deixa recursos
pela metade, e aí é preciso rodar `./infra/destroy.sh` antes de tentar
de novo.

**2. O AWS CLI precisa estar no PATH.** O `lstk aws` não tem cliente
próprio: ele chama o AWS CLI da sua máquina.

```
aws --version
```

**3. No Windows, use o Git Bash a partir daqui.** Os scripts são bash.
O PowerShell da Sprint 0 serviu para instalar; para rodar o projeto,
é o Git Bash.

## Rodar

```
./infra/deploy.sh
```

Um comando, do zero. Ao final ele imprime o endereço da API e o
endereço do site. Abra o site no navegador: o formulário cadastra e a
lista consulta.

Para conferir que tudo faz o que foi prometido:

```
./testes/executar.sh      # os seis criterios de aceite da Sprint 1
./testes/medir.sh         # o p95 da consulta, que o RNF-01 exige
```

Para derrubar tudo:

```
./infra/destroy.sh
```

O par `deploy.sh` → `destroy.sh` → `deploy.sh` tem que funcionar sempre.
É isso que o RNF-03 exige, e é o que prova que nenhum recurso foi criado
por clique.

## Como as pastas estão organizadas

```
docs/        os três documentos entregues, um por template
  01-requisitos.md       Sprint 1, Template 1
  02-arquitetura.md      Sprint 2, Template 2
  diagrama.md            Sprint 2, o diagrama em Mermaid
  03-validacao.md        Sprint 5, Template 3

infra/       tudo que cria recurso na nuvem
  config.sh              os nomes dos recursos, em um lugar só
  01-bucket.sh  ...  08-funcao-marcar.sh
  deploy.sh              chama os anteriores na ordem
  destroy.sh             desfaz
  openapi.yaml           a descrição da API

app/         o código que roda na nuvem
  gravar/handler.py      RF-01, RF-02, RF-05
  consultar/handler.py   RF-03
  marcar/handler.py      RF-04
  site/index.html        a camada de apresentação

testes/      o que prova que funciona
  executar.sh            traduz os seis critérios BDD
  medir.sh               mede o p95 da consulta
```

## O que ler primeiro, se o seu objetivo é entender

1. `docs/01-requisitos.md` — o que foi prometido.
2. `docs/02-arquitetura.md` §6.2 — por que o bairro é a chave de
   partição. É a decisão que mais aparece na arguição.
3. `app/gravar/handler.py` — o comentário do topo explica o que mudou
   em relação ao código genérico do roteiro, e por quê.
4. `docs/03-validacao.md` §4 — a matriz de rastreabilidade, que é onde
   a promessa encontra a evidência.
5. `docs/03-validacao.md` §8.1 — o buraco que a matriz encontrou.

## Uma coisa que este repositório deixa à vista

Na Sprint 1 este projeto prometeu, no RF-02, que a foto da capa seria
guardada no S3. O código do roteiro guarda no S3 a ficha do registro em
JSON, e não a imagem. Tudo rodava, todos os testes de então passavam, e
mesmo assim a promessa não estava cumprida.

Quem encontrou foi a matriz de rastreabilidade da Sprint 5, ao tentar
ligar o RF-02 a uma evidência e não achar nenhuma. A correção está no
`app/gravar/handler.py`: ele guarda as duas coisas, a ficha e a imagem.

É o melhor argumento que existe para preencher a matriz de verdade, em
vez de preenchê-la para entregar.
