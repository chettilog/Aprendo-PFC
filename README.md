# Aprendo

Plataforma gamificada de aprendizagem voltada para estudantes do ensino médio.

## Sobre o produto

O Aprendo utiliza mecânicas de gamificação para engajar estudantes, com foco em **verificação por produção**: o estudante precisa produzir conteúdo próprio (explicações com as suas palavras) para comprovar o aprendizado, em vez de apenas responder quizzes de múltipla escolha.

## Versão publicada

- **Aplicação:** https://aprendo-app.netlify.app
- **API:** https://aprendo-pfc.onrender.com (rota de verificação: `/test-db`)

O servidor da API usa um plano gratuito e é suspenso quando fica sem acessos; a primeira requisição depois disso pode levar cerca de um minuto.

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
- Edição do perfil: escolha do avatar (12 ícones prontos), troca do nome e troca da senha, que exige a senha atual (o e-mail não é editável)
- O avatar aparece no Perfil, na saudação do Início e nos rankings; não há envio de foto

**Proteções de segurança**
- Limite de tentativas: 5 senhas erradas por conta a cada 15 minutos (e 30 por IP, folgado porque numa escola vários alunos saem pelo mesmo IP), 30 cadastros por hora por IP, 20 explicações a cada 10 minutos por aluno e 10 códigos de colega inválidos a cada 15 minutos. Quem passa do limite recebe 429, e o primeiro bloqueio fica nos logs
- Trocar a senha encerra as sessões abertas em outros aparelhos (o token antigo deixa de valer) e devolve um token novo para o aparelho atual
- Excluir a conta exige a senha
- Erros internos não devolvem detalhes do banco ao cliente; JSON malformado e rotas inexistentes recebem respostas curtas, sem o rastro de erro do Express
- O texto do aluno não consegue "fechar" a área da resposta no pedido enviado à IA (os marcadores `<<<` e `>>>` são removidos)
- O IP real do aluno é registrado nos logs mesmo atrás do proxy do Render (`trust proxy`)
- Em produção, a API só aceita chamadas do navegador vindas do endereço do app (`ORIGENS_PERMITIDAS`)
- Todo SQL é parametrizado (sem *SQL injection*), e o corpo das requisições é limitado a 50 KB

**Trilhas e aulas**
- Três trilhas de exemplo: Matemática (Fundamentos de Funções), História (Revolução Industrial) e Geografia (Clima e Tempo), com 5 aulas cada, divididas em dois níveis
- Lista de trilhas por matéria, com o progresso do aluno em cada uma
- Aulas em formato de caminho: concluídas, aula atual e aulas bloqueadas até a anterior ser concluída
- **Níveis de trilha**: o nível 1 tem 3 aulas e o nível 2 tem 2 aulas novas, liberadas quando o aluno conclui todo o nível 1. O caminho mostra uma faixa "Nível 2" com o aviso do que falta
- A liberação também é conferida no servidor: abrir ou responder uma aula bloqueada devolve 403
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
- Botão "Ver minhas respostas anteriores" na aula: mostra cada explicação já enviada, com data, nota, comentário e critérios, e permite reaproveitar o texto

**Gamificação**
- Cada aula vale até 50 XP: suficiente = 50 XP, parcial = 25 XP, insuficiente = 0
- Quem tirou parcial e depois acerta ganha só a diferença (+25); a mesma aula nunca passa de 50 XP
- Uma trava no banco (advisory lock) impede ganhar XP duplicado com envios simultâneos
- A aula só conta como concluída (e libera a próxima) com resultado suficiente
- Nível calculado pelo XP total (um novo nível a cada 100 XP)

**Início e Dashboard**
- Aba **Início**: saudação, botão "Continuar de onde parei" (abre a próxima aula não concluída), nível com o XP que falta e as últimas explicações
- Aba **Dashboard**: indicadores (XP, nível, aulas concluídas, taxa de acerto, nota média, dias seguidos) e gráficos desenhados pelo próprio app:
  - evolução do XP acumulado nos últimos 30 dias (linha)
  - XP ganho por dia na última semana (barras)
  - resultado das explicações: suficiente, parcial e insuficiente (rosca)
  - média de cada critério da rubrica, com o ponto a melhorar
  - desempenho por matéria e melhor nota em cada aula
- Datas calculadas no horário de Brasília

**Auditoria**
- Registro de ações na tabela `logs`: cadastro, login (sucesso e falha), acesso ao perfil, exclusão de conta, consultas externas e acessos negados
- Cada registro guarda ação, usuário, IP, data/hora e resultado, sem armazenar senhas ou tokens
- Aba **Admin**, que só aparece para contas admin (a permissão é conferida de novo no servidor em cada rota):
  - **Visão geral:** alunos cadastrados e ativos na semana, explicações enviadas, nota média, resultados das correções, quem corrigiu (IA, palavras-chave ou filtro) e as 5 aulas com a menor nota média. Só números somados, sem dados de nenhum aluno, e contando apenas explicações de alunos
  - **Logs:** os 100 registros de auditoria mais recentes, com filtro "Só falhas". A própria consulta aos logs também é registrada

**Ranking (aba com dois botões: Colegas e Geral)**
- Cada conta tem um código no formato `Nome#1234` (primeiro nome + número de 4 dígitos sorteado no cadastro)
- **Colegas:** o aluno adiciona colegas digitando o código completo e compara o XP em um ranking só entre eles
- **Geral:** os 20 alunos com mais XP de toda a plataforma; quem está fora do top 20 vê a própria posição embaixo. Empates ficam na mesma posição, e contas de administrador não participam
- Os dois rankings mostram apenas primeiro nome, avatar, nível e XP; o código não aparece no ranking geral
- Opção "Aparecer no ranking", que pode ser desligada a qualquer momento e tira o aluno dos dois rankings

**LGPD**
- Aceite obrigatório dos Termos de Uso e da Política de Privacidade no cadastro, com registro da versão e da data do aceite
- Declaração obrigatória de idade mínima (12 anos) no cadastro, sem coletar a data de nascimento (minimização de dados)
- Documentos acessíveis a qualquer momento (no cadastro e na tela de perfil)
- Nenhum dado pessoal sensível é coletado; a tela da aula avisa para não escrever dados pessoais na explicação
- O texto enviado à IA para correção vai sem nome, e-mail ou identificador do aluno
- Logs sem e-mail por extenso: quando necessário, o e-mail é gravado mascarado (`j***@email.com`)
- Logs apagados automaticamente depois de 6 meses (prazo do Marco Civil da Internet)
- O token de login guarda apenas o id do usuário
- Exclusão de conta pelo próprio titular, com confirmação; as explicações e o XP são removidos, e os logs que restam deixam de identificar a pessoa
- Rankings com exposição mínima (primeiro nome, avatar, nível e XP) e opção de sair a qualquer momento
- Avatar escolhido entre ícones prontos: o sistema não recebe nem guarda fotos de alunos, muitos deles menores de idade

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
│   │   │   ├── autenticacao.js  # verificarToken (JWT e sessão) e exigirPerfil (admin)
│   │   │   └── limites.js       # limite de tentativas (login, cadastro, explicações, colegas)
│   │   ├── rotas/             # Um arquivo por parte do sistema
│   │   │   ├── autenticacao.js  # POST /cadastro, POST /login
│   │   │   ├── usuarios.js      # ver e editar perfil, trocar senha, excluir conta
│   │   │   ├── trilhas.js       # trilhas e aulas
│   │   │   ├── producoes.js     # envio da explicação, nota e XP
│   │   │   ├── dashboard.js     # GET /dashboard (resumo da aba Início)
│   │   │   ├── estatisticas.js  # GET /estatisticas (gráficos da aba Dashboard)
│   │   │   ├── ranking.js       # ranking entre colegas e ranking geral
│   │   │   ├── admin.js         # GET /logs e GET /admin/visao-geral
│   │   │   ├── documentos.js    # termos e política
│   │   │   ├── wiki.js          # consulta à Wikipedia
│   │   │   └── status.js        # GET / e GET /test-db
│   │   ├── servicos/          # Regras de negócio (sem rotas)
│   │   │   ├── avaliacao.js     # filtro, nota e resultado da explicação
│   │   │   ├── ia.js            # chamada ao Gemini com a rubrica
│   │   │   ├── xp.js            # XP por resultado, XP a ganhar e nível
│   │   │   ├── progresso.js     # dias seguidos de estudo e próxima aula
│   │   │   ├── ranking.js       # código Nome#1234 e ordem do ranking
│   │   │   └── logs.js          # auditoria, máscara de e-mail e limpeza dos logs antigos
│   │   └── utils/
│   │       ├── erros.js       # resposta de erro interno sem detalhes do banco
│   │       └── validacoes.js  # validação do cadastro, ids, explicação e avatar
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
│   │   │   ├── avatar.dart      # Os 12 avatares do perfil e a grade de escolha
│   │   │   ├── campo_senha.dart # Campo de senha com botão de mostrar/ocultar
│   │   │   └── cartoes.dart     # Cartões e indicadores usados por várias telas
│   │   └── telas/
│   │       ├── tela_login.dart
│   │       ├── tela_cadastro.dart
│   │       ├── tela_inicio.dart     # Navegação (Início, Trilhas, Dashboard, Ranking, Perfil e Admin)
│   │       ├── tela_admin.dart      # Aba Admin (visão geral e logs)
│   │       ├── tela_painel.dart     # Aba Início
│   │       ├── tela_dashboard.dart  # Aba Dashboard (indicadores e gráficos)
│   │       ├── tela_ranking.dart    # Aba Ranking (colegas e geral)
│   │       ├── tela_respostas.dart  # Respostas anteriores de uma aula
│   │       ├── tela_editar_perfil.dart # Editar nome e trocar senha
│   │       ├── tela_trilhas.dart    # Trilhas e caminho de aulas (com os níveis)
│   │       ├── tela_aula.dart       # Aula, explicação e feedback
│   │       ├── tela_perfil.dart
│   │       ├── tela_documentos.dart # Termos e Política
│   │       └── tela_busca_wiki.dart
│   └── test/                  # Testes do Flutter
├── docs/                      # Diagramas (os atuais ficam em docs/figuras-atuais)
├── INTEGRACAO_API.md
└── README.md
```

## Rotas da API

| Método | Rota | Acesso | Descrição |
|---|---|---|---|
| POST | `/cadastro` | Público | Cria conta (valida os campos e exige aceite dos termos e declaração de idade mínima) |
| POST | `/login` | Público | Autentica e retorna token JWT |
| GET | `/termos` | Público | Termos de Uso |
| GET | `/politica` | Público | Política de Privacidade |
| GET | `/perfil` | JWT | Dados do usuário logado |
| PUT | `/perfil` | JWT | Altera o nome do usuário logado (RF15) |
| PUT | `/perfil/avatar` | JWT | Troca o avatar (número de 0 a 11) (RF15) |
| PUT | `/perfil/senha` | JWT | Troca a senha, exigindo a senha atual (RF15) |
| DELETE | `/minha-conta` | JWT | Exclui a conta do titular, exigindo a senha (`{"senha": "..."}`) |
| GET | `/logs` | JWT + admin | Os 100 logs de auditoria mais recentes (`?falhas=true` traz só as falhas) |
| GET | `/admin/visao-geral` | JWT + admin | Números da plataforma, sem dados pessoais |
| GET | `/wiki/:topico` | JWT | Consulta à Wikipedia |
| GET | `/trilhas` | JWT | Lista as trilhas ativas |
| GET | `/trilhas/:id/aulas` | JWT | Aulas da trilha, com a situação (concluída, parcial) e a melhor nota do aluno |
| GET | `/aulas/:id` | JWT | Conteúdo de uma aula |
| POST | `/aulas/:id/producoes` | JWT | Envia a explicação do aluno, retorna o feedback e o XP |
| GET | `/aulas/:id/producoes` | JWT | Respostas anteriores do aluno na aula, com nota, comentário e critérios |
| GET | `/dashboard` | JWT | Resumo da aba Início (próxima aula, nível, últimas explicações) |
| GET | `/estatisticas` | JWT | Indicadores e dados dos gráficos da aba Dashboard |
| GET | `/ranking` | JWT | Código do aluno e ranking entre ele e os colegas adicionados |
| GET | `/ranking/geral` | JWT | Os 20 alunos com mais XP e a posição do próprio aluno |
| POST | `/ranking/colegas` | JWT | Adiciona um colega pelo código `Nome#1234` |
| DELETE | `/ranking/colegas/:codigo` | JWT | Remove um colega do ranking |
| PUT | `/ranking/visibilidade` | JWT | Liga ou desliga "aparecer no ranking" (colegas e geral) |

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
psql -U postgres -d aprendo_db -f sql/06-aulas-detalhadas.sql
psql -U postgres -d aprendo_db -f sql/07-lgpd-logs.sql
psql -U postgres -d aprendo_db -f sql/08-aulas-resumidas.sql
psql -U postgres -d aprendo_db -f sql/09-ranking.sql
psql -U postgres -d aprendo_db -f sql/10-niveis-trilha.sql
psql -U postgres -d aprendo_db -f sql/11-avatar-ranking-geral.sql
psql -U postgres -d aprendo_db -f sql/12-seguranca.sql
```

O conteúdo das aulas (título, texto, palavras-chave e resposta de referência) é cadastrado por esses scripts, direto na tabela `aulas`. Não há tela de cadastro de aulas no app.

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

Em produção, defina também `ORIGENS_PERMITIDAS` com o endereço do app (ex.: `https://aprendo-app.netlify.app`; vários endereços separados por vírgula). Sem essa variável, qualquer origem é aceita, o que é útil no desenvolvimento local. `PROXIES_CONFIAVEIS` (padrão: 1) é o número de proxies na frente da API.

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

## Contas para teste

O repositório não traz contas prontas nem senhas. Para testar:

- **Aluno:** crie uma conta pela tela de cadastro (ou pela rota `POST /cadastro`).
- **Administrador:** crie uma conta comum e promova-a pelo banco de dados, trocando o e-mail no comando abaixo:

```sql
UPDATE usuarios SET perfil = 'admin' WHERE email = 'email-da-conta@exemplo.com';
```

Os testes manuais em `backend/testes.http` usam contas fictícias de um banco local; a senha do administrador local é definida na variável `@senhaAdmin`, no início do arquivo.
