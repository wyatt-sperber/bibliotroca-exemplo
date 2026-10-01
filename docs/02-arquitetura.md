# Documento de Arquitetura

Projeto: BiblioTroca\
Cenário oficial escolhido: nenhum, projeto-exemplo da disciplina\
Data: 01/10/2026\
Versão: 1.0

Entregável da Sprint 2, no formato do Template 2.

## 1. Requisitos não funcionais

Fórmula obrigatória: `[Categoria] + [Métrica Numérica Mensurável] + [Condição de Execução]`.

### RNF-01

```
requisito
  Desempenho: a consulta dos livros de um bairro deve responder
  em no máximo 800 ms no percentil 95, com até 500 livros na
  partição consultada e 30 requisições seguidas.

serviço AWS
  Amazon DynamoDB

pilar do Well-Architected
  4, Eficiência de Performance

razão
  O número não é estético: ele é o que obriga a consulta a ser
  um query na partição e não um scan na tabela. Um scan passa no
  teste com 10 livros e falha com 10 mil, porque o tempo cresce
  com a tabela inteira. O query cresce só com a partição.
```

### RNF-02

```
requisito
  Segurança: a função de gravação deve ter permissão de escrita
  apenas na tabela e no bucket deste projeto, e nenhuma permissão
  de exclusão, verificável na política anexada ao papel.

serviço AWS
  AWS IAM

pilar do Well-Architected
  2, Segurança

razão
  O menor privilégio aqui não é teoria: a função recebe conteúdo
  vindo da internet. Se ela puder apagar, uma falha dela vira
  perda de dado e não só dado errado.
```

### RNF-03

```
requisito
  Confiabilidade: o ambiente inteiro deve ser reconstruído do
  zero em no máximo 3 minutos, com um único comando, partindo de
  um emulador sem nenhum recurso.

serviço AWS
  Amazon S3, Amazon DynamoDB, AWS Lambda, Amazon API Gateway

pilar do Well-Architected
  3, Confiabilidade

razão
  É o requisito que torna o `deploy.sh` obrigatório. Enquanto
  existir um recurso criado por clique, a reconstrução depende de
  alguém lembrar do clique — e ninguém lembra.
```

### RNF-04

```
requisito
  Observabilidade: toda execução das funções deve deixar registro
  no CloudWatch Logs com o identificador do livro e o bairro,
  disponível em no máximo 10 segundos após a chamada.

serviço AWS
  Amazon CloudWatch Logs

pilar do Well-Architected
  1, Excelência Operacional

razão
  Sem o registro, uma gravação que falhou e uma que nunca chegou
  são indistinguíveis. O `print` dentro da função é o que torna o
  CloudWatch útil, e por isso ele é requisito e não hábito.
```

### 1.1 Resumo

| ID | Categoria | Métrica | Serviço AWS | Pilar |
|---|---|---|---|---|
| RNF-01 | Desempenho | p95 ≤ 800 ms, 500 livros na partição | Amazon DynamoDB | 4 |
| RNF-02 | Segurança | zero permissões de exclusão na política | AWS IAM | 2 |
| RNF-03 | Confiabilidade | reconstrução total ≤ 3 min, 1 comando | S3, DynamoDB, Lambda, API Gateway | 3 |
| RNF-04 | Observabilidade | registro visível ≤ 10 s após a chamada | Amazon CloudWatch Logs | 1 |

Pilares: 1 Excelência Operacional, 2 Segurança, 3 Confiabilidade, 4 Eficiência de Performance, 5 Otimização de Custos, 6 Sustentabilidade.

### 1.2 O pilar não contemplado

O pilar 5, Otimização de Custos, não aparece como requisito. Em ambiente emulado não existe fatura, então qualquer métrica de custo que escrevêssemos seria inventada — e requisito inventado é pior do que requisito ausente, porque dá a impressão de ter sido verificado.

O que o projeto faz, mesmo sem o requisito, é escolher serviços cujo custo real seria proporcional ao uso: DynamoDB em modo sob demanda e Lambda, que só cobram quando há chamada. Um servidor ligado o mês inteiro para atender a um catálogo de bairro seria a decisão cara.

O pilar 6, Sustentabilidade, segue a mesma lógica do 5 e pela mesma razão.

## 2. A arquitetura em três camadas

| Camada | O que fica nela, neste projeto | Serviço AWS |
|---|---|---|
| Apresentação | A página `index.html`, com o formulário de cadastro e a lista do bairro | Amazon S3, em modo site estático |
| Negócio | As três funções: `gravar`, `consultar` e `marcar`, mais o roteamento | AWS Lambda e Amazon API Gateway |
| Dados | A tabela de livros e os arquivos — fichas e capas | Amazon DynamoDB e Amazon S3 |

### 2.1 Como a separação é garantida

A página é um arquivo estático servido pelo S3. Ela não tem credencial nenhuma: o `config.js` carrega apenas a URL pública da API. Mesmo que alguém leia todo o código-fonte da página no navegador — e qualquer um pode —, não há nada ali que permita falar com o DynamoDB.

O único caminho até os dados é o API Gateway, e o API Gateway só sabe invocar as três funções. Quem decide o que pode ser gravado é a função, não o navegador. É por isso que a validação dos campos obrigatórios está no `handler.py` e não no JavaScript: a validação da página é conveniência para o usuário, a da função é a que vale.

## 3. Estilo arquitetural

| Item | Resposta |
|---|---|
| Estilo adotado | Distribuído, com serviços independentes atrás de um ponto único de entrada |
| Por que ele serve a este projeto | Cadastro, consulta e marcação têm cargas muito diferentes: consulta é o que mais acontece, cadastro é raro, marcação é rara. Funções separadas permitem que cada uma escale sozinha, e uma falha no cadastro não derruba a consulta. |
| Estilo descartado | Repository |
| Por que foi descartado | O estilo Repository supõe um repositório central com o qual vários componentes conversam livremente. Aqui isso significaria dar acesso ao banco a quem não precisa, e o RNF-02 pede exatamente o contrário. |

Estilos: Data Flow, Call and Return, Implicit Invocation, Repository, Distributed, Virtual Machines.

## 4. Padrões arquiteturais identificados

| Padrão | Onde ele aparece no meu desenho | O que ele resolve aqui |
|---|---|---|
| API Gateway | O Amazon API Gateway, como ponto único de entrada das três rotas | Dá um endereço só para o navegador, e tira das funções a responsabilidade de roteamento e CORS |
| Layered Architecture | A separação entre a página, as funções e os dados | Impede que a camada de apresentação conheça o formato do dado armazenado |
| Function as a Service | Cada operação é uma função independente | Permite publicar correção de uma operação sem republicar as outras |

### 4.1 O padrão que faria falta

**Circuit Breaker.** Hoje, se o DynamoDB ficasse lento, a função de consulta ficaria esperando até o tempo-limite e devolveria erro — uma vez por requisição, para cada requisição. Com um Circuit Breaker, depois de algumas falhas seguidas a função pararia de tentar por alguns segundos e devolveria uma resposta de indisponibilidade imediata.

Ele entraria dentro da função `consultar`, em volta da chamada ao `query`. Não foi implementado porque, no recorte atual, há um só consumidor e nenhuma dependência externa ao projeto — o padrão resolveria um problema que ainda não existe aqui, e código que resolve problema inexistente também custa manutenção.

## 5. Diagrama de arquitetura de ponta a ponta

O diagrama está em `docs/diagrama.md`, em Mermaid, e é renderizado pelo próprio GitHub ao abrir o arquivo.

### 5.1 Legenda das caixas

| Caixa | Serviço AWS | O que ela faz | Requisito que a justifica |
|---|---|---|---|
| Navegador | — | Exibe o formulário e a lista, e envia a foto em base64 | US-01, US-02 |
| Site estático | Amazon S3 | Serve `index.html` e `config.js` | RF-03, camada de apresentação |
| Entrada da API | Amazon API Gateway | Recebe as três rotas e invoca a função certa | Padrão API Gateway |
| Função gravar | AWS Lambda | Valida, salva a capa e a ficha, grava o livro | RF-01, RF-02, RF-05 |
| Função consultar | AWS Lambda | Faz o `query` na partição do bairro e ordena | RF-03, RNF-01 |
| Função marcar | AWS Lambda | Regrava o livro como indisponível | RF-04 |
| Tabela de livros | Amazon DynamoDB | Guarda o livro, com `bairro` como chave de partição | RF-01, RNF-01 |
| Bucket de arquivos | Amazon S3 | Guarda a capa em `capas/` e a ficha em `fichas/` | RF-02 |
| Papel da função | AWS IAM | Concede à função só o que ela usa | RNF-02 |
| Registros | Amazon CloudWatch Logs | Guarda o que cada execução imprimiu | RNF-04 |

### 5.2 O fluxo de uma requisição

O morador preenche título, autor, bairro e estado de conservação, escolhe a foto da capa e clica em "Disponibilizar". O navegador lê o arquivo, converte para base64 e envia tudo em um único POST para a rota `/livros` do API Gateway.

O API Gateway invoca a função `gravar`. Ela desserializa o corpo, confere os quatro campos obrigatórios e recusa com 400 se faltar algum, dizendo qual. Confere se o estado é um dos três aceitos. Gera o identificador do livro.

A foto vai primeiro: a função decodifica o base64, recusa acima de 2 MB e grava a imagem no S3 em `capas/<bairro>/<id>.jpg`. Só depois disso o livro é gravado na tabela. A ordem é o requisito de Reliability levantado no FURPS da Sprint 1 — não pode existir livro listado apontando para uma imagem que nunca subiu.

Com o livro na tabela, a função grava também a ficha em JSON em `fichas/<bairro>/<id>.json`, imprime uma linha de registro e devolve 201 com o identificador e os dois endereços.

A página então consulta sozinha: um GET em `/livros?bairro=<bairro>`, que chega na função `consultar`. Ela faz um `query` na partição do bairro, descarta os já trocados, ordena do mais recente para o mais antigo e devolve a lista. A tabela aparece preenchida na tela.

### 5.3 O que acontece se uma caixa cair

| Caixa | Efeito da queda | O que o sistema ainda consegue fazer |
|---|---|---|
| Site estático | Ninguém chega pela tela | A API continua respondendo: outro cliente, ou o `curl`, continua cadastrando e consultando |
| Função gravar | Nenhum livro novo entra | A consulta continua devolvendo todo o acervo já cadastrado |
| Função consultar | A tela fica vazia | Os cadastros continuam sendo aceitos e nada se perde; a lista volta quando a função voltar |
| Tabela de livros | Nada funciona | Nada. As fichas em JSON no S3 permitem reconstruir o acervo, mas isso é recuperação, não operação |
| Bucket de arquivos | O cadastro com foto falha antes de gravar o livro | A consulta continua; cadastros sem foto continuariam, se a foto fosse opcional na tela |

## 6. Modelo de dados

### 6.1 Entidades

| Entidade | Campo | Tipo | Obrigatório |
|---|---|---|---|
| Livro | `bairro` | texto, chave de partição | sim |
| Livro | `id_livro` | texto, chave de ordenação | sim, gerado |
| Livro | `titulo` | texto | sim |
| Livro | `autor` | texto | sim |
| Livro | `estado` | texto: novo, bom ou gasto | sim |
| Livro | `disponivel` | texto: sim ou nao | sim, começa em "sim" |
| Livro | `criado_em` | texto, data e hora em ISO 8601 | sim, gerado |
| Livro | `capa` | texto, caminho do objeto no S3 | não |

### 6.2 A chave de partição

A chave de partição é o **bairro**.

A regra para escolher não é qual campo identifica o item, e sim **qual campo aparece em toda consulta**. A pergunta que a tela responde é "o que tem disponível perto de mim", e perto de mim é o bairro. Toda consulta do sistema filtra por bairro, nenhuma consulta pede "todos os livros de todos os bairros".

O identificador do livro **não** serve como chave de partição, embora seja único. Se ele fosse a partição, cada livro ficaria em uma partição só dele, e listar um bairro exigiria varrer a tabela inteira — exatamente o scan que o RNF-01 proíbe.

O `id_livro` entra como chave de ordenação, o que dá à chave primária a unicidade de que ela precisa e permite que um mesmo bairro tenha muitos livros.

### 6.3 O que fica no S3 e o que fica no DynamoDB

No DynamoDB fica o que é consultado: os campos do livro, pequenos e filtráveis. É o que a tela lista.

No S3 ficam os arquivos: a capa em `capas/<bairro>/<id>.jpg` e a ficha completa em `fichas/<bairro>/<id>.json`. Nenhum dos dois é consultado por filtro — são buscados pelo endereço exato, que a tabela guarda.

A separação tem uma razão de custo e uma de desempenho. Guardar uma imagem de 2 MB dentro de um item do DynamoDB é caro e, acima de 400 KB, impossível: é o limite de tamanho de item do serviço. E a consulta de um bairro ficaria lenta carregando imagens que a lista nem exibe.

A ficha em JSON parece redundante com a tabela, e em parte é. Ela existe como registro imutável do que foi recebido: se um dia o formato da tabela mudar, as fichas continuam contando o que o sistema aceitou naquele dia.

## 7. Backlog priorizado

| Ordem | Item | Origem | Prioridade | Sprint |
|---|---|---|---|---|
| 1 | Cadastrar livro com os quatro campos e gerar identificador | RF-01, US-01 | essencial | 3 |
| 2 | Guardar a foto da capa no S3 | RF-02, US-01 | essencial | 3 |
| 3 | Recusar cadastro incompleto dizendo o campo | RF-05, US-01 c2 | essencial | 3 |
| 4 | Listar os livros disponíveis do bairro, do mais recente ao mais antigo | RF-03, US-02 | essencial | 4 |
| 5 | Página com formulário e lista | US-01, US-02 | essencial | 4 |
| 6 | Marcar o livro como trocado | RF-04, US-03 | importante | 4 |
| 7 | Avisar quando o bairro não tem livros | US-02 c2 | importante | 4 |

### 7.1 Distribuição

Os itens 1 a 3 são a Sprint 3: é tudo que acontece no caminho da gravação, e nenhum deles precisa de API nem de tela para ser verificado — a função é invocada direto, como o roteiro faz.

Os itens 4 a 7 são a Sprint 4: todos dependem de haver o que listar, e todos passam pela API ou pela página.

A ordem dentro de cada sprint segue a dependência real. O item 2 não pode vir antes do 1 porque a chave da capa inclui o identificador do livro, e o identificador nasce no item 1.

## 8. Recorte de implementação

Tudo que está no backlog acima será implementado. Não há item declarado na Sprint 1 que esteja fora do recorte.

Isso foi uma decisão, e teve custo: a US-03 obrigou a escrever uma terceira função, `marcar`, que o roteiro não ensina. A alternativa seria declarar a US-03 fora do recorte e registrar isso na matriz de rastreabilidade da Sprint 5 — o que é uma resposta legítima e teria sido mais barata.

Optamos por implementar porque a US-03 é o que impede o catálogo de encher de livros que já saíram. Sem ela, o RNF-01 piora sozinho com o tempo: a partição cresce com livros que ninguém mais pode pegar, e a consulta fica lenta por lixo.

Fica **fora do escopo**, como já declarado na Sprint 1: combinar data e local da troca, conta de usuário, e qualquer informação de localização além do bairro — esta última por força do RD-01.

## 9. Decisões e alternativas descartadas

| Decisão | Alternativa descartada | Por quê |
|---|---|---|
| Filtrar os disponíveis e ordenar dentro da função | Índice secundário global por `disponivel` e `criado_em` | A partição de um bairro é pequena por construção: são os livros de um bairro. Filtrar alguns itens em memória custa menos que manter um índice. Acima de alguns milhares de livros por bairro, a decisão certa passa a ser o índice — e esse é o ponto exato em que esta decisão deve ser revista. |
| A foto viaja em base64 dentro do POST | Upload direto ao S3 com URL pré-assinada | A URL pré-assinada é o padrão correto para arquivos grandes e evita passar a imagem pela função. Com limite de 2 MB e um cadastro raro, o ganho não paga o segundo passo de rede e o código extra nesta disciplina. |
| Regravar o item inteiro ao marcar como trocado | `update_item` com expressão de atualização | O `put_item` já foi ensinado na Sprint 3. Regravar a mesma chave primária substitui o item, e assim a terceira função não introduz nenhum comando novo. Com muitos campos ou escrita concorrente, o `update_item` seria o certo. |
| Bairro como texto livre | Lista fechada de bairros | Texto livre aceita "Tijuca" e "tijuca" como partições diferentes, o que é um defeito conhecido e está declarado na Sprint 5. A lista fechada resolveria, ao custo de manter a lista. |

## 10. Revisão cruzada recebida

| Pergunta | Resposta recebida |
|---|---|
| Todo RNF tem número e condição de execução? | Sim, nos quatro. |
| Toda caixa do diagrama tem um requisito que a justifica? | Sim. A revisão perguntou pela caixa do CloudWatch, que parecia decorativa, e ela está ligada ao RNF-04. |
| A chave de partição é justificada pela consulta, e não pela unicidade? | Sim, e a justificativa explica por que o identificador não serve. |
| O recorte diz o que fica de fora? | Ficou. A primeira versão só dizia o que entrava. |

### 10.1 O que foi ajustado depois da revisão

A seção 8 originalmente listava apenas o que seria implementado. A equipe revisora apontou que, lendo só aquele texto, não dava para saber se algo da Sprint 1 havia sido abandonado ou esquecido. A seção passou a declarar explicitamente o que fica fora e por quê.

A seção 9 ganhou a linha sobre o bairro como texto livre. Ela não estava lá porque era um defeito conhecido que ninguém tinha escrito — e defeito conhecido e não escrito é indistinguível de defeito não percebido.
