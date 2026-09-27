# Aprendo

Plataforma gamificada de aprendizagem voltada para estudantes do ensino médio.

## Sobre o produto

O Aprendo utiliza mecânicas de gamificação para engajar estudantes, com foco em **verificação por produção**: o estudante precisa produzir conteúdo próprio (resumos, explicações) para comprovar seu aprendizado, em vez de apenas responder quizzes de múltipla escolha.

## Tecnologias

- **Frontend:** Flutter Web
- **Backend:** Node.js + Express
- **Banco de dados:** PostgreSQL
- **Segurança:** JWT (autenticação) + bcrypt (criptografia de senhas)

## Funcionalidades implementadas

**Autenticação e controle de acesso**
- Cadastro com senha criptografada (hash bcrypt)
- Login com geração de token JWT (expiração de 2 horas)
- Rotas protegidas por middleware de validação do token
- Tela de perfil acessível apenas a usuários autenticados
- Logout com remoção do token

**Auditoria**
- Registro de ações na tabela `logs`: cadastro, login (sucesso e falha), acesso ao perfil, exclusão de conta e consultas externas
- Cada registro guarda ação, usuário, IP, data/hora e resultado — sem armazenar senhas ou tokens
- Consulta dos logs pela rota protegida `GET /logs`

**LGPD**
- Aceite obrigatório dos Termos de Uso e da Política de Privacidade no cadastro, com registro da versão e da data do aceite
- Documentos servidos pelo backend e acessíveis a qualquer momento (no cadastro e na tela de perfil)
- Exclusão de conta pelo próprio titular, com confirmação; os logs são preservados de forma anonimizada

**Integração com API externa**
- Consulta à Wikipedia via proxy no backend (o IP do usuário não é exposto ao serviço externo)
- Documentação técnica completa em [`INTEGRACAO_API.md`](INTEGRACAO_API.md)

## Estrutura do projeto

```
aprendo/
├── backend/
│   ├── documentos/        # Termos de Uso e Política de Privacidade
│   ├── db.js              # Conexão com o PostgreSQL
│   ├── server.js          # Rotas da API
│   └── testes.http        # Testes das rotas (extensão REST Client)
├── frontend/
│   └── lib/main.dart      # Telas do aplicativo
├── INTEGRACAO_API.md
└── README.md
```

## Rotas da API

| Método | Rota | Acesso | Descrição |
|---|---|---|---|
| POST | `/cadastro` | Público | Cria conta (exige aceite dos termos) |
| POST | `/login` | Público | Autentica e retorna token JWT |
| GET | `/termos` | Público | Termos de Uso |
| GET | `/politica` | Público | Política de Privacidade |
| GET | `/perfil` | JWT | Dados do usuário logado |
| GET | `/logs` | JWT | Logs de auditoria |
| GET | `/wiki/:topico` | JWT | Consulta à Wikipedia |
| DELETE | `/minha-conta` | JWT | Exclui a conta do titular |

## Como rodar o projeto

### Pré-requisitos

- Git
- Node.js (LTS)
- PostgreSQL 15+
- Flutter SDK
- Google Chrome

### 1. Clonar o repositório

```bash
git clone https://github.com/chettilog/Aprendo-PFC.git
cd Aprendo-PFC
git checkout entrega2809
```

### 2. Configurar o banco de dados

Acesse o PostgreSQL:

```bash
psql -U postgres
```

Crie o banco e as tabelas:

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
  termos_versao VARCHAR(10)
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

Saia com `\q`.

### 3. Rodar o backend

```bash
cd backend
npm install
```

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

O Chrome abre automaticamente na tela de login.