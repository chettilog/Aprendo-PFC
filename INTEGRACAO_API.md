# Integração com API Externa — Wikipedia

## Objetivo

Complementar o conteúdo pedagógico do Aprendo com resumos enciclopédicos. O aluno pesquisa um tópico (ex: "Fotossíntese") e recebe título, descrição, resumo, imagem e link da fonte.

## API utilizada

| Item | Valor |
|---|---|
| Serviço | Wikipedia REST API (Wikimedia Foundation) |
| Endpoint | `GET https://pt.wikipedia.org/api/rest_v1/page/summary/{titulo}` |
| Autenticação | Não exige chave de API |
| Formato | JSON |

## Arquitetura: proxy no backend

O frontend **nunca** chama a Wikipedia diretamente. O fluxo é:

```
Flutter  →  GET /wiki/:topico (backend Aprendo, exige JWT)  →  Wikipedia
Flutter  ←  resposta filtrada                               ←  backend
```

Motivos dessa decisão:

- **Privacidade:** a Wikipedia recebe apenas o IP do servidor do Aprendo, nunca o IP do aluno
- **Controle de acesso:** só usuários autenticados podem consultar
- **Auditoria:** toda consulta é registrada na tabela `logs`
- **Minimização de dados:** o backend repassa ao frontend apenas os campos necessários

## Endpoint interno

**Requisição**

```
GET /wiki/:topico
Authorization: Bearer <token JWT>
```

**Resposta de sucesso (200)**

```json
{
  "titulo": "Fotossíntese",
  "descricao": "processo físico-químico celular...",
  "resumo": "Fotossíntese é o processo pelo qual plantas...",
  "link": "https://pt.wikipedia.org/wiki/Fotoss%C3%ADntese",
  "imagem": "https://upload.wikimedia.org/..."
}
```

**Códigos de resposta**

| Código | Situação |
|---|---|
| 200 | Tópico encontrado |
| 400 | Tópico não informado |
| 401 | Token não enviado |
| 403 | Token inválido ou expirado |
| 404 | Tópico não encontrado na Wikipedia |
| 502 | Falha na comunicação com a Wikipedia |
| 500 | Erro interno |

## Auditoria

Cada consulta gera um registro na tabela `logs`:

- `busca_wiki` — consulta com resultado (sucesso)
- `busca_wiki_sem_resultado` — tópico não encontrado (falha)

O registro guarda o termo pesquisado, o usuário, o IP e o horário. Nenhum dado pessoal é enviado à Wikipedia — apenas o termo pesquisado.

## Onde está no código

- `backend/server.js` — rota `app.get('/wiki/:topico')`
- `frontend/lib/main.dart` — classe `TelaBuscaWiki`
- `backend/testes.http` — testes da rota

## Como testar

**Pelo sistema:** faça login → tela de perfil → **Explorar conteúdo** → pesquise um tópico.

**Pela API:** faça login no `testes.http`, copie o token, cole no bloco "Wiki - com token" e clique em **Send Request**.

## Limitações conhecidas

- A busca diferencia acentos ("Fotossíntese" funciona, "Fotossintese" pode não encontrar)
- Se a Wikipedia estiver indisponível, a funcionalidade retorna erro 502