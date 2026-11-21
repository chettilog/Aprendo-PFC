// Ponto de entrada do backend: só liga o servidor.
// A aplicação (rotas, middlewares) é montada em src/app.js.
const app = require('./src/app');
const { iaConfigurada } = require('./src/servicos/ia');
const { agendarLimpezaDeLogs } = require('./src/servicos/logs');

// Sem a chave dos tokens, ninguém conseguiria entrar: melhor não ligar e avisar o motivo
if (!process.env.JWT_SECRET) {
  console.error('ERRO: defina a variável JWT_SECRET (veja o .env.example)');
  process.exit(1);
}
// Uma chave curta pode ser adivinhada por força bruta
if (process.env.JWT_SECRET.length < 32) {
  console.warn('AVISO: JWT_SECRET tem menos de 32 caracteres; use uma chave longa e aleatória');
}

// Usa a porta definida pelo ambiente (Render) ou 3000 no computador local
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}`);
  // Mostra no log se a correção por IA está ativa (depende da variável GEMINI_API_KEY)
  console.log(iaConfigurada()
    ? 'Correcao por IA: LIGADA'
    : 'Correcao por IA: DESLIGADA (GEMINI_API_KEY nao definida) - usando palavras-chave');
  // LGPD: apaga os logs com mais de 6 meses, agora e depois uma vez por dia
  agendarLimpezaDeLogs();
});
