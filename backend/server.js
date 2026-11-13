// Ponto de entrada do backend: só liga o servidor.
// A aplicação (rotas, middlewares) é montada em src/app.js.
const app = require('./src/app');

// Usa a porta definida pelo ambiente (Render) ou 3000 no computador local
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}`);
});
