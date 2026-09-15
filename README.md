# Aprendo

Plataforma gamificada de aprendizagem voltada para estudantes do ensino médio, desenvolvida como Projeto Final de Curso (PFC).

## Sobre o projeto

O Aprendo utiliza mecânicas de gamificação para engajar estudantes do ensino médio no processo de aprendizagem, com foco em **verificação por produção** — o estudante precisa produzir conteúdo (resumos, explicações) para comprovar seu aprendizado, ao invés de apenas responder quizzes de múltipla escolha.

## Tecnologias

- **Frontend:** Flutter Web
- **Backend:** Node.js + Express
- **Banco de dados:** PostgreSQL

## Funcionalidades implementadas

- Cadastro de usuário (interface + API + persistência no banco, com senha criptografada via bcrypt)

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
```

### 2. Configurar o banco

Acesse o PostgreSQL:

```bash
psql -U postgres
```

Crie o banco e a tabela:

```sql
CREATE DATABASE aprendo_db;
\c aprendo_db
CREATE TABLE usuarios (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  senha VARCHAR(255) NOT NULL,
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
DB_PASSWORD=postgres123
DB_NAME=aprendo_db
```

Inicie o servidor:

```bash
node server.js
```

Backend rodando em `http://localhost:3000`.

### 4. Rodar o frontend

Em outro terminal:

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

O Chrome abre automaticamente com a tela de cadastro.