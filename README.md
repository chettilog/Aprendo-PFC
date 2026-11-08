# Aprendo

Plataforma gamificada de aprendizagem voltada para estudantes do ensino médio.

## Sobre o produto

O Aprendo utiliza mecânicas de gamificação para engajar estudantes, com foco em **verificação por produção**: o estudante precisa produzir conteúdo próprio (explicações com as suas palavras) para comprovar o aprendizado, em vez de apenas responder quizzes de múltipla escolha.

## Tecnologias

- **Frontend:** Flutter Web
- **Backend:** Node.js + Express
- **Banco de dados:** PostgreSQL
- **Segurança:** JWT (autenticação) + bcrypt (criptografia de senhas)

## Funcionalidades implementadas

**Autenticação e controle de acesso**
- Cadastro e login com validação dos campos na tela e no servidor (nome, formato do e-mail e tamanho da senha)
- Senhas criptografadas com bcrypt e login com token JWT (expiração de 2 horas)
- Perfis de usuário (`aluno` e `admin`), com permissões verificadas no backend a cada requisição
- Logout com remoção do token

**Trilhas e aulas**
- Lista de trilhas por matéria, com o progresso do aluno em cada uma
- Aulas em formato de caminho: concluídas, aula atual e aulas bloqueadas até a anterior ser concluída

**Verificação por produção**
- Ao final de cada aula, o aluno escreve uma explicação com as próprias palavras (mínimo de 40 caracteres)
- A explicação é avaliada pelas palavras-chave da aula e recebe um feedback: suficiente ou insuficiente, com dicas do que faltou
- Uma explicação insuficiente pode ser refeita

**Gamificação**
- 50 XP na primeira explicação suficiente de cada aula (a mesma aula não pontua duas vezes)
- Nível calculado pelo XP total (um novo nível a cada 100 XP)

**Dashboard**
- Nível, XP total, aulas concluídas e explicações enviadas em destaque
- Gráfico do XP ganho nos últimos 7 dias e progresso por trilha

**Auditoria**
- Registro de ações na tabela `logs`: cadastro, login (sucesso e falha), acesso ao perfil, exclusão de conta, consultas externas e acessos negados
- Cada registro guarda ação, usuário, IP, data/hora e resultado, sem armazenar senhas ou tokens
- Consulta dos logs pela rota `GET /logs`, restrita ao perfil admin

**LGPD**
- Aceite obrigatório dos Termos de Uso e da Política de Privacidade no cadastro, com registro da versão e da data do aceite
- Documentos acessíveis a qualquer momento (no cadastro e na tela de perfil)
- Exclusão de conta pelo próprio titular, com confirmação; as explicações e o XP do usuário são removidos, e os logs são preservados de forma anonimizada

**Integração com API externa**
- Consulta à Wikipedia via proxy no backend (o IP do usuário não é exposto ao serviço externo)
- Documentação técnica completa em [`INTEGRACAO_API.md`](INTEGRACAO_API.md)

## Estrutura do projeto

```
aprendo/
├── backend/
│   ├── documentos/        # Termos de Uso e Política de Privacidade
│   ├── sql/               # Scripts das tabelas e dados de exemplo
│   ├── db.js              # Conexão com o PostgreSQL
│   ├── server.js          # Rotas da API
│   └── testes.http        # Testes das rotas (extensão REST Client)
├── frontend/
│   ├── lib/
│   │   ├── main.dart          # Login, cadastro, perfil e documentos legais
│   │   ├── tela_inicio.dart   # Navegação principal (Início, Trilhas, Perfil)
│   │   ├── tela_painel.dart   # Dashboard
│   │   ├── tela_trilhas.dart  # Trilhas e caminho de aulas
│   │   ├── tela_aula.dart     # Aula, explicação e feedback
│   │   ├── api.dart           # Endereço do backend e chamadas à API
│   │   ├── tema.dart          # Cores e tema visual
│   │   └── validacoes.dart    # Regras de validação dos formulários
│   └── test/              # Testes do Flutter
├── docs/                  # Diagrama de classes e BPMN
├── INTEGRACAO_API.md
└── README.md
```

## Rotas da API

| Método | Rota | Acesso | Descrição |
|---|---|---|---|
| POST | `/cadastro` | Público | Cria conta (valida os campos e exige aceite dos termos) |
| POST | `/login` | Público | Autentica e retorna token JWT |
| GET | `/termos` | Público | Termos de Uso |
| GET | `/politica` | Público | Política de Privacidade |
| GET | `/perfil` | JWT | Dados do usuário logado |
| DELETE | `/minha-conta` | JWT | Exclui a conta do titular |
| GET | `/logs` | JWT + admin | Logs de auditoria |
| GET | `/wiki/:topico` | JWT | Consulta à Wikipedia |
| GET | `/trilhas` | JWT | Lista as trilhas ativas |
| GET | `/trilhas/:id/aulas` | JWT | Aulas da trilha, indicando as concluídas pelo aluno |
| GET | `/aulas/:id` | JWT | Conteúdo de uma aula |
| POST | `/aulas/:id/producoes` | JWT | Envia a explicação do aluno, retorna o feedback e o XP |
| GET | `/aulas/:id/producoes` | JWT | Explicações do aluno na aula, com o feedback |
| GET | `/dashboard` | JWT | Dados do dashboard do aluno |

## Como rodar o projeto

### Pré-requisitos

- Git
- Node.js (LTS)
- PostgreSQL 15+
- Flutter SDK
- Google Chrome

### 1. Clonar o repositório

```bash
git clone https://github.com/chettilog/Aprendo-PFC.git aprendo
cd aprendo
git checkout entrega0911
```

### 2. Configurar o banco de dados

Acesse o PostgreSQL:

```bash
psql -U postgres
```

Crie o banco e as tabelas de usuários e logs:

```sql
CREATE DATABASE aprendo_db;
\c aprendo_db

CREATE TABLE usuarios (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  senha VARCHAR(255) NOT NULL,
  criado_em TIMESTAMP DEFAULT NOW(),
  termos_aceitos_em TIMESTAMP,
  termos_versao VARCHAR(10),
  perfil VARCHAR(20) NOT NULL DEFAULT 'aluno'
);

CREATE TABLE logs (
  id SERIAL PRIMARY KEY,
  usuario_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
  acao VARCHAR(50) NOT NULL,
  detalhes VARCHAR(255),
  ip VARCHAR(45),
  sucesso BOOLEAN DEFAULT true,
  criado_em TIMESTAMP DEFAULT NOW()
);
```

Saia com `\q`. Depois, na pasta `backend`, rode os scripts das demais tabelas e dos dados de exemplo, nesta ordem:

```bash
cd backend
psql -U postgres -d aprendo_db -f sql/01-tabelas-conteudo.sql
psql -U postgres -d aprendo_db -f sql/02-dados-exemplo.sql
psql -U postgres -d aprendo_db -f sql/03-palavras-chave.sql
```

Os scripts podem ser executados mais de uma vez sem duplicar dados.

### 3. Rodar o backend

Na pasta `backend`:

```bash
npm install
```

> No Windows, se o PowerShell bloquear o comando `npm`, use `npm.cmd install`.

Crie um arquivo `.env` na pasta `backend`:

```
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=sua_senha_do_postgres
DB_NAME=aprendo_db
JWT_SECRET=defina_uma_chave_secreta_longa
```

Inicie o servidor:

```bash
node server.js
```

Backend disponível em `http://localhost:3000`.

### 4. Rodar o frontend

Em outro terminal:

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

O Chrome abre automaticamente na tela de login. O endereço do backend fica em `frontend/lib/api.dart`.

### 5. Criar um usuário administrador

Por segurança, nenhum usuário consegue se tornar administrador pela interface. Cadastre uma conta normalmente pelo app e promova-a direto no banco:

```bash
psql -U postgres -d aprendo_db
```

```sql
UPDATE usuarios SET perfil = 'admin' WHERE email = 'email_da_conta@exemplo.com';
```

## Testes

- **API:** abra `backend/testes.http` no VS Code com a extensão REST Client. Envie primeiro o login de cada seção; os demais testes usam o token automaticamente.
- **Frontend:** na pasta `frontend`, rode `flutter test`.

## Contas de teste (ambiente local)

Contas usadas no desenvolvimento. Elas existem apenas no banco local e precisam ser cadastradas em um banco novo.

| Perfil | E-mail | Senha |
|---|---|---|
| Aluno | `comtermos@teste.com` | `123456` |
| Admin | `admin@aprendo.com` | `123456` |
