# Documento de Requisitos

Entregável da Sprint 1, no formato do Template 1.

Este é o documento do projeto-exemplo da disciplina. Ele usa um cenário
que **não é nenhum dos dois oficiais**, de propósito: ele existe para
mostrar a forma e o nível de detalhe esperados, não o conteúdo. Se o
documento da sua equipe sair parecido com este no conteúdo, alguma
coisa deu errado.

Projeto: BiblioTroca\
Cenário oficial escolhido: nenhum, projeto-exemplo da disciplina\
Data: 01/10/2026\
Versão: 1.0

## 1. O cenário

### 1.1 Cenário escolhido

Exemplo didático. Um catálogo de livros que moradores de um bairro disponibilizam para troca entre si.

### 1.2 O problema, em linguagem comum

Quem termina um livro raramente volta a lê-lo, e quem quer ler um livro específico frequentemente conhece alguém a duas ruas de distância que o tem parado na estante. Hoje esse encontro depende de acaso: alguém comenta em um grupo de mensagens, a mensagem se perde entre outras trinta, e o livro continua parado. Não existe nenhum lugar onde seja possível ver o que está disponível no bairro sem pedir a alguém que lembre.

### 1.3 O recorte

| Dentro do escopo | Fora do escopo |
|-------------------------------------------|-------------------------------|
| Cadastro de um livro disponível, com foto da capa | Combinar data e local da troca |
| Consulta dos livros disponíveis em um bairro | Cadastro e autenticação de usuário |
| Marcação de um livro como indisponível | Avaliação ou reputação de quem troca |
| Consulta de um livro específico pelo identificador | Entrega, frete ou pagamento |

### 1.4 Por que este recorte

O sistema só tem valor se houver o que consultar, e só há o que consultar se cadastrar for fácil. Cadastro e consulta são, portanto, o par mínimo que faz a aplicação existir.

Combinar a troca acontece hoje por mensagem direta, e funciona: o que falta não é o combinado, é a descoberta. Autenticação foi deixada de fora porque o catálogo é público por natureza, e exigir conta para olhar reduziria o uso justamente na fase em que ele precisa crescer.

## 2. Requisitos funcionais

| ID | Requisito | Serviço AWS citado | Prioridade |
|------|------------------------------------------------------------|--------|------|
| RF-01 | O sistema deve registrar um livro com título, autor, bairro e estado de conservação, gerando um identificador único a cada cadastro. | — | essencial |
| RF-02 | O sistema deve armazenar a foto da capa enviada no cadastro no Amazon S3, no momento da confirmação do registro. | Amazon S3 | essencial |
| RF-03 | O sistema deve listar os livros disponíveis de um bairro consultando o Amazon DynamoDB, ordenados do cadastro mais recente para o mais antigo. | Amazon DynamoDB | essencial |
| RF-04 | O sistema deve alterar a situação de um livro para indisponível quando o dono informar que a troca ocorreu. | — | importante |
| RF-05 | O sistema deve recusar o cadastro de um livro sem título ou sem bairro, informando qual campo faltou. | — | essencial |

### 2.1 Verificação da estrutura

| ID | Verbo | Objeto | Condição |
|------|--------|---------------------|----------------------------------------|
| RF-01 | registrar | um livro | gerando identificador único a cada cadastro |
| RF-02 | armazenar | a foto da capa | no momento da confirmação do registro |
| RF-03 | listar | os livros de um bairro | ordenados do mais recente ao mais antigo |
| RF-04 | alterar | a situação de um livro | quando o dono informar a troca |
| RF-05 | recusar | o cadastro incompleto | informando qual campo faltou |

## 3. Requisitos de domínio

| ID | Restrição | Origem | O que ela impede ou obriga |
|------|--------------------------|--------------|--------------------------------|
| RD-01 | O bairro é a única informação de localização coletada. | LGPD, princípio da minimização | Impede pedir endereço, CEP ou coordenada no cadastro. |
| RD-02 | A foto enviada não pode conter pessoas identificáveis. | LGPD, dado pessoal em imagem | Obriga o aviso no formulário de que a foto é da capa, não do dono. |

## 4. Histórias de usuário

### US-01

```
Como morador que tem livros parados na estante
Eu quero disponibilizar um livro com a foto da capa
Para que quem procura por ele descubra que ele existe
sem precisar me perguntar
```

### US-02

```
Como morador procurando uma leitura
Eu quero ver os livros disponíveis no meu bairro
Para que eu consiga escolher sem depender de alguém
lembrar de mim
```

### US-03

```
Como morador que já trocou o livro
Eu quero marcar que ele não está mais disponível
Para que ninguém perca tempo procurando algo que já saiu
```

## 5. Critérios de aceite em BDD

### US-01, cenário 1

```
Dado que preencho título, autor, bairro e estado, e anexo uma
foto de capa
Quando confirmo o cadastro
Então o sistema devolve um identificador e a foto fica
acessível pelo endereço devolvido
```

### US-01, cenário 2

```
Dado que deixo o campo bairro em branco
Quando confirmo o cadastro
Então o sistema recusa o envio, informa que o bairro é
obrigatório, e nenhum livro é criado
```

### US-02, cenário 1

```
Dado que o bairro Tijuca tem 3 livros disponíveis e 1 já
trocado
Quando consulto os livros da Tijuca
Então a lista traz exatamente 3 livros, do mais recente para
o mais antigo
```

### US-02, cenário 2

```
Dado que o bairro Grajaú não tem nenhum livro cadastrado
Quando consulto os livros do Grajaú
Então a tela informa que ainda não há livros nesse bairro, e
não exibe uma lista vazia sem explicação
```

### US-03, cenário 1

```
Dado que sou o dono de um livro disponível
Quando marco o livro como trocado
Então ele deixa de aparecer na consulta do bairro na
requisição seguinte
```

### US-03, cenário 2

```
Dado que informo um identificador de livro que não existe
Quando tento marcá-lo como trocado
Então o sistema informa que o livro não foi encontrado e
nenhum outro registro é alterado
```

### 5.1 O cenário de exceção

Três dos seis tratam exceção. O de US-01, cenário 2, trata campo obrigatório ausente. O de US-02, cenário 2, trata lista vazia. O de US-03, cenário 2, trata identificador inexistente.

## 6. Avaliação INVEST

| História | I | N | V | E | S | T | O que seria ajustado |
|---------|------|------|------|------|------|------|--------------------------------------------|
| US-01 | sim | sim | sim | sim | sim | sim | — |
| US-02 | não | sim | sim | sim | sim | sim | depende de US-01 para ter o que listar |
| US-03 | não | sim | sim | sim | sim | sim | depende de US-01 para ter o que marcar |

### 6.1 Justificativa das reprovações

US-02 e US-03 falham no **I**, de Independent, e a dependência é real: não há como listar ou marcar livros antes que exista cadastro.

A alternativa seria fundir as três em uma só, mas isso reprovaria no **S**, de Small, porque a história resultante não caberia em uma sprint.

Optamos por manter as três separadas e assumir a dependência explicitamente, ordenando o backlog de modo que US-01 venha primeiro. Dependência declarada e ordenada custa menos do que uma história grande demais para estimar.

## 7. Qualidade pelo FURPS

| Categoria | Preocupação principal no meu cenário |
|-------|-------------------------------------------------------------------|
| Functionality | Livro marcado como trocado não pode continuar aparecendo na consulta, porque isso gera contato inútil e frustração. |
| Usability | O cadastro precisa ser concluído pelo celular, com uma mão, em menos de um minuto, sem nenhuma instrução prévia. |
| Reliability | Se o envio da foto falhar, o cadastro não pode ficar pela metade, com um livro registrado apontando para uma imagem inexistente. |
| Performance | A consulta do bairro é a tela de entrada: se ela demorar, a pessoa fecha antes de ver o primeiro livro. |
| Supportability | A lista de bairros atendidos muda conforme o projeto cresce, e precisa mudar sem alteração de código. |

## 8. Decisões e alternativas descartadas

| Decisão | Alternativa considerada | Por que não foi escolhida |
|-------|---------------|----------------------------------------------------|
| O recorte do cenário | Incluir o agendamento da troca dentro do sistema | Agendar exige identidade, notificação e confirmação das duas partes. Triplicaria o escopo para resolver a parte que já funciona por mensagem. |
| Quais cinco requisitos | Trocar o RF-05 por uma busca por título | A busca é mais atraente de demonstrar, mas sem validação de campo o catálogo se enche de registro incompleto e a busca passa a devolver lixo. Validar vem antes. |
| Qual caso de exceção | Tratar apenas o campo obrigatório ausente | O caso de bairro sem livros é o mais provável no começo do projeto, quando quase todo bairro está vazio. Ignorá-lo faria a primeira impressão ser uma tela em branco. |

## 9. Revisão cruzada recebida

Revisado por: equipe 3\
Data: 19/08/2026

| Pergunta | Resposta da equipe revisora |
|-------------------------|-------------------------------------------------|
| Algum requisito está escrito como decisão de arquitetura? | Não. O RF-02 e o RF-03 citam serviços, mas dentro de um comportamento observável. |
| Algum "para que" é circular? | O de US-03 era. Estava escrito "para que o sistema fique atualizado", que é benefício do sistema, não de pessoa. |
| Algum cenário BDD cobre só o caminho feliz? | Não. Três dos seis tratam exceção. |
| Alguma história falha no S do INVEST? | Não, mas US-02 e US-03 falham no I, e isso não estava declarado. |

### 9.1 O que foi ajustado depois da revisão

O "para que" de US-03 foi reescrito, passando de "para que o sistema fique atualizado" para "para que ninguém perca tempo procurando algo que já saiu". O benefício agora é de uma pessoa, e não do próprio sistema.

A dependência de US-02 e US-03 em relação a US-01 passou a ser declarada na seção 6.1, com a justificativa de por que mantê-las separadas mesmo assim.
