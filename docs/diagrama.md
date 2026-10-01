# Diagrama de arquitetura — BiblioTroca

Entregável da Sprint 2, seção 5. O GitHub renderiza o bloco abaixo como
imagem ao abrir este arquivo.

```mermaid
flowchart TB
    subgraph apresentacao["Camada de apresentação"]
        nav["Navegador<br/>formulário e lista"]
        site["Amazon S3<br/>site estático<br/>index.html + config.js"]
    end

    subgraph negocio["Camada de negócio"]
        api["Amazon API Gateway<br/>estágio dev"]
        gravar["AWS Lambda<br/>gravar<br/>RF-01 RF-02 RF-05"]
        consultar["AWS Lambda<br/>consultar<br/>RF-03"]
        marcar["AWS Lambda<br/>marcar<br/>RF-04"]
    end

    subgraph dados["Camada de dados"]
        tabela["Amazon DynamoDB<br/>bibliotroca-livros<br/>partição: bairro"]
        bucket["Amazon S3<br/>bibliotroca-capas<br/>capas/ e fichas/"]
    end

    subgraph apoio["Apoio"]
        papel["AWS IAM<br/>papel da função<br/>RNF-02"]
        logs["Amazon CloudWatch Logs<br/>RNF-04"]
    end

    nav -->|"carrega a página"| site
    nav -->|"POST /livros"| api
    nav -->|"GET /livros?bairro="| api
    nav -->|"POST /livros/trocado"| api

    api --> gravar
    api --> consultar
    api --> marcar

    gravar -->|"put_object<br/>capa e ficha"| bucket
    gravar -->|"put_item"| tabela
    consultar -->|"query na partição"| tabela
    marcar -->|"query + put_item"| tabela

    papel -.->|"autoriza"| gravar
    papel -.->|"autoriza"| consultar
    papel -.->|"autoriza"| marcar

    gravar -.->|"print"| logs
    consultar -.->|"print"| logs
    marcar -.->|"print"| logs
```

## Como ler

As setas cheias são o caminho do dado. As pontilhadas são autorização e
registro: não carregam dado do usuário, mas sem elas nada funciona e
nada é auditável.

Repare que **nenhuma seta liga o navegador diretamente à tabela ou ao
bucket**. Esse é o desenho da separação em três camadas descrito na
seção 2.1 do documento de arquitetura: o único caminho até os dados
passa pelo API Gateway e por uma função.

Repare também que a função `gravar` tem duas setas de saída, e a ordem
importa: primeiro o bucket, depois a tabela. É o requisito de
Reliability do FURPS — não pode sobrar um livro listado apontando para
uma imagem que nunca subiu.
