// Monta a aplicação Express: middlewares globais + todas as rotas.
// Fica separado do server.js para os testes poderem usar o app sem abrir uma porta.
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

// O Render fica na frente da API como proxy: sem isto, todo pedido pareceria vir do IP do proxy,
// e os logs e o limite de tentativas usariam o IP errado. O valor é o número de proxies confiáveis.
app.set('trust proxy', Number(process.env.PROXIES_CONFIAVEIS || 1));
// Não anuncia que o servidor usa Express
app.disable('x-powered-by');

// Permite que o servidor entenda requisições com corpo em JSON (até 50 KB: uma explicação tem no máximo 3000 caracteres)
app.use(express.json({ limit: '50kb' }));
// Quais sites podem chamar a API pelo navegador. Em produção, ORIGENS_PERMITIDAS recebe o endereço do app
// (ex.: https://aprendo-app.netlify.app); sem a variável, qualquer origem é aceita (desenvolvimento local)
const origens = (process.env.ORIGENS_PERMITIDAS || '').split(',').map(o => o.trim()).filter(Boolean);
app.use(cors(origens.length ? { origin: origens } : {}));

// Cada arquivo da pasta rotas/ cuida de uma parte do sistema
app.use(require('./rotas/status'));       // GET /  e  GET /test-db
app.use(require('./rotas/autenticacao')); // POST /cadastro, POST /login
app.use(require('./rotas/usuarios'));     // GET e PUT /perfil, PUT /perfil/avatar, PUT /perfil/senha, DELETE /minha-conta
app.use(require('./rotas/admin'));        // GET /logs e GET /admin/visao-geral (só admin)
app.use(require('./rotas/documentos'));   // GET /termos, GET /politica
app.use(require('./rotas/wiki'));         // GET /wiki/:topico
app.use(require('./rotas/trilhas'));      // GET /trilhas, /trilhas/:id/aulas, /aulas/:id
app.use(require('./rotas/producoes'));    // POST e GET /aulas/:id/producoes
app.use(require('./rotas/dashboard'));    // GET /dashboard (resumo da tela Início)
app.use(require('./rotas/estatisticas')); // GET /estatisticas (aba Dashboard, com os gráficos)
app.use(require('./rotas/ranking'));      // ranking entre colegas (código Nome#1234) e ranking geral

// Endereço que não existe: responde em JSON, sem a página padrão do Express
app.use((req, res) => {
  res.status(404).json({ error: 'Rota não encontrada' });
});

// Erros que chegam aqui (JSON malformado, corpo grande demais...) recebem resposta curta,
// sem o rastro de erro (stack trace) que o Express mostraria por padrão
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'JSON inválido' });
  if (err.type === 'entity.too.large') return res.status(413).json({ error: 'Conteúdo grande demais' });
  console.error('[erro]', err.message);
  res.status(500).json({ error: 'Erro interno do servidor' });
});

module.exports = app;
