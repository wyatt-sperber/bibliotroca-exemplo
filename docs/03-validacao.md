# Documento de Validação

Projeto: BiblioTroca\
Cenário oficial escolhido: nenhum, projeto-exemplo da disciplina\
Data: 01/10/2026\
Versão: 1.0

Entregável da Sprint 5, no formato do Template 3.

> **Sobre os números deste documento.** Eles vieram de uma execução
> real, com o LocalStack rodando em um notebook Windows pelo Git Bash,
> na mesma configuração que a Sprint 0 monta. Os seus números serão
> outros, porque a máquina é outra. Rode na sua e escreva os seus: um
> relatório com o número de outra pessoa não é medição, é cópia.

## 1. Reconstrução do ambiente

| Item | Resposta |
|---|---|
| Tempo do `deploy.sh` a partir do ambiente vazio | abaixo de 3 min, dentro do exigido pelo RNF-03. Para registrar o número exato, rode `time ./infra/deploy.sh` |
| Comandos necessários | um: `./infra/deploy.sh` |
| Algum recurso criado fora do script? | não |
| O `destroy.sh` apaga tudo que o `deploy.sh` cria? | sim, verificado rodando `deploy` → `destroy` → `deploy` |

O ciclo foi executado com o emulador vazio: nenhum bucket, nenhuma tabela, nenhuma função. É o que o RNF-03 exige, e é a única forma de saber que não sobrou nada criado por clique.

## 2. Critérios de aceite executados

O script `testes/executar.sh` traduz literalmente os seis critérios declarados na Sprint 1. Cada bloco do script tem, em comentário, o "Dado / Quando / Então" que ele verifica. Alguns critérios precisam de mais de uma verificação, porque a frase afirma mais de uma coisa — o C1, por exemplo, afirma que o sistema devolve um identificador **e** que a foto fica acessível.

| Critério | O que ele afirma | Verificações | Resultado |
|---|---|---|---|
| US-01 c1 | Cadastro completo devolve identificador e a foto fica acessível | C1a, C1b | passou |
| US-01 c2 | Bairro em branco é recusado, dizendo qual campo faltou | C2a, C2b | passou |
| US-02 c1 | Bairro com 3 disponíveis e 1 trocado lista 3, do mais recente ao mais antigo | C3a, C3b | passou |
| US-02 c2 | Bairro sem livros informa total zero | C4 | passou |
| US-03 c1 | Marcar como trocado tira o livro da consulta seguinte | C5 | passou |
| US-03 c2 | Identificador inexistente devolve não encontrado e não altera nada | C6a, C6b | passou |

### 2.1 Saída do script

```
OK     C1a cadastro completo devolve identificador
OK     C1b a foto esta no S3 no endereco devolvido
OK     C2a cadastro sem bairro devolve 400
OK     C2b a recusa diz qual campo faltou
OK     C3a o bairro com 1 trocado lista exatamente 3
OK     C3b a lista vem do mais recente para o mais antigo
OK     C4 bairro sem livros devolve total zero
OK     C5 marcar como trocado tira o livro da consulta
OK     C6a identificador inexistente devolve 404
OK     C6b nenhum outro registro foi alterado

passaram: 10   falharam: 0
```

### 2.2 Cenários não verificáveis por script

O RD-02 — "a foto enviada não pode conter pessoas identificáveis" — não é verificável por script. Nenhum teste automatizado sabe se há uma pessoa na imagem.

O que foi feito foi o possível: o aviso está no formulário, acima do campo de arquivo, com o texto que a restrição exige. A verificação é humana, e está registrada aqui como humana em vez de ser disfarçada de teste.

## 3. Requisitos não funcionais medidos

| ID | O que foi prometido | O que foi medido | Resultado |
|---|---|---|---|
| RNF-01 | p95 da consulta ≤ 800 ms | p95 de 49,5 ms em 30 amostras | cumprido |
| RNF-02 | escrita só na tabela e no bucket do projeto, zero exclusão | a política permite `PutItem`, `Query` e `GetItem` apenas no ARN de `bibliotroca-livros`, e `PutObject` e `GetObject` apenas em `bibliotroca-capas`; nenhuma ação `Delete*` | cumprido |
| RNF-03 | reconstrução total ≤ 3 min, um comando | `deploy.sh` do zero, um comando | cumprido |
| RNF-04 | registro visível ≤ 10 s após a chamada | linha impressa pela função aparece no `logs tail` imediatamente | cumprido |

### 3.1 Saída da medição

```
amostras:    30
minimo (s):  0.032291
mediana (s): 0.041782
p95 (s):     0.049516
maximo (s):  0.052640
```

O que interessa aqui não é o número isolado, é a distância entre o menor e o maior: 32 ms contra 53 ms, menos do que o dobro. Uma distribuição apertada assim quer dizer que nenhuma chamada destoou, e que a margem para os 800 ms prometidos é de dezesseis vezes.

A medição começa com uma chamada de aquecimento, descartada. Ela existe porque a primeira execução de uma função inclui a partida dela, que pode ser dez vezes mais lenta que as seguintes e não representa o regime normal. É também por isso que o requisito foi escrito em percentil e não em média: a média de trinta chamadas com uma partida dentro esconderia justamente a chamada que o usuário percebe como lenta.

### 3.2 Requisitos verificados por análise

O RNF-02 não tem número a medir: ele afirma um limite. A verificação foi ler a política anexada ao papel com `iam get-role-policy` e conferir duas coisas — que nenhuma ação começa com `Delete`, e que o campo `Resource` de cada bloco aponta para um recurso nomeado deste projeto, e não para `*`. Está registrado como análise, não como medição.

Há uma exceção declarada, e ela está comentada dentro do `infra/03-papel.sh`: o bloco das ações de registro continua com `Resource: "*"`. O grupo de registros nasce com o nome da função, que só existe depois que a função é criada, e a função precisa do papel para ser criada. Restringir ali exigiria inverter uma ordem que não se inverte.

Vale registrar como este requisito quase passou por cumprido sem estar. A política do roteiro usa `Resource: "*"` em todos os blocos, o que significa qualquer tabela e qualquer bucket da conta. Nada falhava, nenhum teste reclamava, e o RNF-02 estava escrito. Foi ao abrir o `03-papel.sh` para preencher esta linha que a diferença entre o que estava prometido e o que estava concedido apareceu.

## 4. Matriz de rastreabilidade

| Requisito | Onde foi implementado | Método de verificação | Evidência | Resultado |
|---|---|---|---|---|
| RF-01 registrar livro com identificador | `app/gravar/handler.py` | teste automatizado | C1a | cumprido |
| RF-02 guardar a foto no S3 | `app/gravar/handler.py` | teste automatizado | C1b | cumprido |
| RF-03 listar os disponíveis do bairro, ordenados | `app/consultar/handler.py` | teste automatizado | C3a, C3b | cumprido |
| RF-04 marcar o livro como indisponível | `app/marcar/handler.py` | teste automatizado | C5, C6a | cumprido |
| RF-05 recusar cadastro incompleto dizendo o campo | `app/gravar/handler.py` | teste automatizado | C2a, C2b | cumprido |
| RD-01 bairro como única informação de local | modelo de dados, `docs/02-arquitetura.md` §6.1 | análise | a tabela não tem campo de endereço | cumprido |
| RD-02 foto sem pessoas identificáveis | aviso em `app/site/index.html` | análise humana | o aviso está no formulário | cumprido em parte |
| US-01 disponibilizar um livro | `gravar` + formulário | teste automatizado | C1, C2 | cumprido |
| US-02 ver os livros do bairro | `consultar` + lista | teste automatizado | C3, C4 | cumprido |
| US-03 marcar como trocado | `marcar` + botão na lista | teste automatizado | C5, C6 | cumprido |
| RNF-01 p95 ≤ 800 ms | `query` na partição | medição | §3.1 | cumprido |
| RNF-02 menor privilégio no IAM | `infra/03-papel.sh` | análise | §3.2 | cumprido |
| RNF-03 reconstrução ≤ 3 min | `infra/deploy.sh` | medição | §1 | cumprido |
| RNF-04 registro no CloudWatch | `print` nas três funções | análise | linha visível no `logs tail` | cumprido |

### 4.1 Resumo

| Resultado | Quantidade |
|---|---|
| Cumprido | 13 |
| Cumprido em parte | 1 |
| Não cumprido | 0 |

O único "em parte" é o RD-02, e a razão está na seção 2.2: a restrição é real, mas a verificação não é automatizável. Declarar "cumprido" ali seria afirmar uma garantia que o sistema não dá.

## 5. Homologação recebida

A equipe homologadora clonou o repositório, seguiu apenas o `README.md` e não fez nenhuma pergunta durante o processo.

| Pergunta | Resposta |
|---|---|
| O `deploy.sh` rodou do zero sem intervenção? | sim |
| A página abriu e cadastrou um livro? | sim |
| A consulta devolveu o livro cadastrado? | sim |
| Três linhas da matriz conferidas batem com o que o sistema faz? | sim: RF-02, RF-04 e RNF-01 |
| Algo no README estava errado ou faltando? | sim, ver abaixo |

### 5.1 O que foi corrigido depois da homologação

O README não dizia que o `lstk` precisa estar rodando antes do `deploy.sh`. Quem homologou rodou o script com o emulador parado e recebeu um erro de conexão que não explicava nada. A seção de pré-requisitos passou a dizer isso na primeira linha, com o comando de verificação.

O README também não mencionava que a primeira execução do `deploy.sh` é mais lenta, porque baixa a imagem. Quem homologou achou que tinha travado e interrompeu na metade, o que deixou recursos pela metade e exigiu um `destroy.sh` antes de tentar de novo.

## 6. Homologação realizada

Homologamos o projeto de outra equipe seguindo o mesmo roteiro.

| Item | Resultado |
|---|---|
| O README foi suficiente para rodar sem perguntar nada? | não |
| O `deploy.sh` rodou do zero? | sim, na segunda tentativa |
| O que faltava | o README não dizia qual versão do Python a função usa, e o `create-function` falhou com a versão padrão da máquina |

O que essa experiência ensinou, e que vale mais que o apontamento: um README se escreve para quem não participou do projeto. Quem escreveu o nosso já sabia que o emulador precisava estar de pé, e por isso não escreveu.

## 7. O que não foi cumprido

Nada do que foi declarado na Sprint 1 ficou sem implementação. O que existe são três limites conhecidos, declarados aqui porque limite conhecido e não escrito é indistinguível de limite não percebido.

**O bairro é texto livre.** "Tijuca" e "tijuca" são partições diferentes, e um morador que digitar diferente não encontra os livros do próprio bairro. A correção é uma lista fechada de bairros no formulário, e está registrada como decisão descartada em `docs/02-arquitetura.md` §9.

**A consulta filtra e ordena em memória.** Funciona porque a partição de um bairro é pequena. Acima de alguns milhares de livros no mesmo bairro, o certo passa a ser um índice secundário. O ponto de revisão está declarado na mesma seção 9.

**Não há autenticação.** Qualquer um pode marcar qualquer livro como trocado, inclusive um que não é seu. Isso está dentro do que a Sprint 1 declarou fora de escopo — o catálogo é público por natureza —, mas a US-03 diz "sou o dono do livro", e hoje o sistema não sabe quem é o dono. É a primeira coisa a fazer se o projeto continuar.

## 8. Fechamento

### 8.1 O que funcionou melhor do que o esperado

A matriz de rastreabilidade. Ela parecia burocracia até ser preenchida, e foi preenchendo que apareceu o buraco do RF-02: o documento prometia a foto no S3 desde a Sprint 1, e a implementação estava guardando só a ficha em JSON. O requisito estava escrito, o código estava rodando, os testes estavam passando — e mesmo assim a promessa não estava cumprida. Sem a matriz, isso teria chegado ao Demoday.

### 8.2 O que deu mais trabalho do que o esperado

A terceira função. A US-03 foi escrita na Sprint 1 em dois minutos, e implementá-la custou uma função, um script de infraestrutura, uma rota no OpenAPI, uma linha no deploy e dois testes. A lição não é que a história estava errada — ela é boa —, é que o custo de uma frase na Sprint 1 não aparece na Sprint 1.

### 8.3 O que você faria diferente se recomeçasse

Escreveria o `testes/executar.sh` na Sprint 1, junto com os critérios de aceite, mesmo sabendo que ele falharia por meses. Os seis critérios já estavam escritos em "Dado / Quando / Então" desde o começo — virar script é quase tradução. Tendo o script desde o início, cada sprint teria terminado com um número em vez de uma impressão, e o buraco do RF-02 teria aparecido na Sprint 3 em vez da Sprint 5.

## 9. Repositório

| Item | Resposta |
|---|---|
| Endereço | o repositório onde este documento está |
| Branch com o estado final | `main` |
| Branches por sprint | `sprint-1` a `sprint-5`, cada uma congelada no fim da sprint |
| O `README.md` é suficiente para um terceiro rodar? | sim, depois das correções da seção 5.1 |
