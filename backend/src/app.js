// Monta a aplicação Express: middlewares globais + todas as rotas.
// Fica separado do server.js para os testes poderem usar o app sem abrir uma porta.
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Permite que o servidor entenda requisições com corpo em JSON
app.use(express.json());
// Libera o acesso de outras origens (o Flutter Web, por exemplo)
app.use(cors());

// Cada arquivo da pasta rotas/ cuida de uma parte do sistema
app.use(require('./rotas/status'));       // GET /  e  GET /test-db
app.use(require('./rotas/autenticacao')); // POST /cadastro, POST /login
app.use(require('./rotas/usuarios'));     // GET /perfil, DELETE /minha-conta
app.use(require('./rotas/admin'));        // GET /logs (só admin)
app.use(require('./rotas/documentos'));   // GET /termos, GET /politica
app.use(require('./rotas/wiki'));         // GET /wiki/:topico
app.use(require('./rotas/trilhas'));      // GET /trilhas, /trilhas/:id/aulas, /aulas/:id
app.use(require('./rotas/producoes'));    // POST e GET /aulas/:id/producoes
app.use(require('./rotas/dashboard'));    // GET /dashboard

module.exports = app;
