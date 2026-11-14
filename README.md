# Aprendo

Plataforma gamificada de aprendizagem voltada para estudantes do ensino médio.

## Sobre o produto

O Aprendo utiliza mecânicas de gamificação para engajar estudantes, com foco em **verificação por produção**: o estudante precisa produzir conteúdo próprio (explicações com as suas palavras) para comprovar o aprendizado, em vez de apenas responder quizzes de múltipla escolha.

## Tecnologias

- **Frontend:** Flutter Web
- **Backend:** Node.js + Express
- **Banco de dados:** PostgreSQL
- **Segurança:** JWT (autenticação) + bcrypt (criptografia de senhas)
- **Correção das explicações:** Google Gemini (IA) com rubrica, com reserva por palavras-chave
- **Testes:** Jest + Supertest (backend) e flutter_test (frontend)
- **Hospedagem:** Neon (banco), Render (backend) e Netlify (site)

## Funcionalidades implementadas

**Autenticação e controle de acesso**
- Cadastro e login com validação dos campos na tela e no servidor (nome, formato do e-mail e tamanho da senha)
- Senhas criptografadas com bcrypt e login com token JWT (expiração de 2 horas)
- Perfis de usuário (`aluno` e `admin`), com permissões verificadas no backend a cada requisição
- Logout com remoção do token

**Trilhas e aulas**
- Três trilhas de exemplo: Matemática (Fundamentos de Funções), História (Revolução Industrial) e Geografia (Clima e Tempo), com 3 aulas cada
- Lista de trilhas por matéria, com o progresso do aluno em cada uma
- Aulas em formato de caminho: concluídas, aula atual e aulas bloqueadas até a anterior ser concluída
- Cada aula do caminho mostra a melhor nota do aluno; a aula com acerto parcial fica marcada como "falta completar"
- Ao abrir uma trilha, a tela rola sozinha até a aula atual

**Verificação por produção**
- Ao final de cada aula, o aluno escreve uma explicação com as próprias palavras (mínimo de 40 caracteres)
- A explicação recebe uma **nota de 0 a 100**, em 3 etapas:
  1. **Filtro local**: texto sem sentido (letras aleatórias), lista de palavras soltas ou cópia do texto da aula recebe nota 0, sem chamar a IA
  2. **IA com rubrica**: conceito correto (até 50) + completude em relação à resposta de referência (até 30) + clareza com palavras próprias (até 20)
     - Se a IA estiver sobrecarregada ou demorar, o sistema tenta até 3 vezes (modelo principal, modelo de reserva, principal de novo), esperando 1 s e depois 2 s
  3. **Reserva**: se todas as tentativas falharem ou não houver chave configurada, a nota vem da proporção de palavras-chave da aula citadas
- Resultado: nota ≥ 70 é **suficiente**, de 40 a 69 é **parcial**, abaixo de 40 é **insuficiente**, sempre com um comentário do que faltou
- A explicação pode ser refeita para melhorar a nota

**Gamificação**
- Cada aula vale até 50 XP: suficiente = 50 XP, parcial = 25 XP, insuficiente = 0
- Quem tirou parcial e depois acerta ganha só a diferença (+25); a mesma aula nunca passa de 50 XP
- Uma trava no banco (advisory lock) impede ganhar XP duplicado com envios simultâneos
- A aula só conta como concluída (e libera a próxima) com resultado suficiente
- Nível calculado pelo XP total (um novo nível a cada 100 XP)

**Dashboard**
- Botão "Continuar de onde parei", que abre a próxima aula não concluída
- Nível, com quanto XP falta para o próximo
- Dias seguidos de estudo, XP total, aulas concluídas e nota média em destaque
- Últimas 3 explicações, com a nota de cada uma
- Gráfico do XP ganho nos últimos 7 dias e progresso por trilha
- Datas calculadas no horário de Brasília

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
│   ├── server.js              # Ponto de entrada: só liga o servidor
│   ├── src/
│   │   ├── app.js             # Monta o Express e registra todas as rotas
│   │   ├── config/
│   │   │   └── banco.js       # Conexão com o PostgreSQL
│   │   ├── middlewares/
│   │   │   └── autenticacao.js  # verificarToken (JWT) e exigirPerfil (admin)
│   │   ├── rotas/             # Um arquivo por parte do sistema
│   │   │   ├── autenticacao.js  # POST /cadastro, POST /login
│   │   │   ├── usuarios.js      # GET /perfil, DELETE /minha-conta
│   │   │   ├── trilhas.js       # trilhas e aulas
│   │   │   ├── producoes.js     # envio da explicação, nota e XP
│   │   │   ├── dashboard.js     # GET /dashboard
│   │   │   ├── admin.js         # GET /logs
│   │   │   ├── documentos.js    # termos e política
│   │   │   ├── wiki.js          # consulta à Wikipedia
│   │   │   └── status.js        # GET / e GET /test-db
│   │   ├── servicos/          # Regras de negócio (sem rotas)
│   │   │   ├── avaliacao.js     # filtro, nota e resultado da explicação
│   │   │   ├── ia.js            # chamada ao Gemini com a rubrica
│   │   │   ├── xp.js            # XP por resultado, XP a ganhar e nível
│   │   │   ├── progresso.js     # dias seguidos de estudo e próxima aula
│   │   │   └── logs.js          # registro de auditoria
│   │   └── utils/
│   │       └── validacoes.js  # validação do cadastro, ids e explicação
│   ├── testes/                # Testes automáticos (Jest)
│   ├── documentos/            # Termos de Uso e Política de Privacidade
│   ├── sql/                   # Scripts das tabelas e dados de exemplo
│   └── testes.http            # Testes manuais das rotas (REST Client)
├── frontend/
│   ├── lib/
│   │   ├── main.dart          # Ponto de entrada do app
│   │   ├── api.dart           # Endereço do backend e chamadas à API
│   │   ├── tema.dart          # Cores e tema visual
│   │   ├── validacoes.dart    # Regras de validação dos formulários
│   │   ├── componentes/
│   │   │   └── campo_senha.dart # Campo de senha com botão de mostrar/ocultar
│   │   └── telas/
│   │       ├── tela_login.dart
│   │       ├── tela_cadastro.dart
│   │       ├── tela_inicio.dart     # Navegação (Início, Trilhas, Perfil)
│   │       ├── tela_painel.dart     # Dashboard
│   │       ├── tela_trilhas.dart    # Trilhas e caminho de aulas
│   │       ├── tela_aula.dart       # Aula, explicação e feedback
│   │       ├── tela_perfil.dart
│   │       ├── tela_documentos.dart # Termos e Política
│   │       └── tela_busca_wiki.dart
│   └── test/                  # Testes do Flutter
├── docs/                      # Diagrama de classes e BPMN
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
| GET | `/trilhas/:id/aulas` | JWT | Aulas da trilha, com a situação (concluída, parcial) e a melhor nota do aluno |
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
git checkout entrega1611
```

### 2. Configurar o banco de dados

Acesse o PostgreSQL:

```bash
psql -U postgres
```

Crie o banco:

```sql
CREATE DATABASE aprendo_db;
```

Saia com `\q`. Depois, na pasta `backend`, rode os scripts nesta ordem:

```bash
cd backend
psql -U postgres -d aprendo_db -f sql/00-tabelas-base.sql
psql -U postgres -d aprendo_db -f sql/01-tabelas-conteudo.sql
psql -U postgres -d aprendo_db -f sql/02-dados-exemplo.sql
psql -U postgres -d aprendo_db -f sql/03-palavras-chave.sql
psql -U postgres -d aprendo_db -f sql/04-avaliacao-por-nota.sql
psql -U postgres -d aprendo_db -f sql/05-novas-trilhas.sql
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
GEMINI_API_KEY=sua_chave_do_google_ai_studio
```

A `GEMINI_API_KEY` é gratuita (https://aistudio.google.com/apikey). Sem ela, o sistema funciona normalmente e corrige pelas palavras-chave. O modelo pode ser trocado com `GEMINI_MODELO` (padrão: `gemini-flash-latest`) e o de reserva com `GEMINI_MODELO_RESERVA` (padrão: `gemini-flash-lite-latest`).

Inicie o servidor:

```bash
npm start
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

- **Testes automáticos do backend:** na pasta `backend`, rode `npm test` (ou `npm run cobertura` para ver a porcentagem de código coberta; o relatório fica em `backend/coverage/index.html`). Os testes não precisam de banco nem de internet: o banco e a IA são simulados.
- **API manual:** abra `backend/testes.http` no VS Code com a extensão REST Client. Envie primeiro o login de cada seção; os demais testes usam o token automaticamente.
- **Frontend:** na pasta `frontend`, rode `flutter test`.

## Contas de teste (ambiente local)

Contas usadas no desenvolvimento. Elas existem apenas no banco local e precisam ser cadastradas em um banco novo.

| Perfil | E-mail | Senha |
|---|---|---|
| Aluno | `comtermos@teste.com` | `123456` |
| Admin | `admin@aprendo.com` | `123456` |
