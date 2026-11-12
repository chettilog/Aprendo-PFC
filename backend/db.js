// Importa o módulo Pool do pacote 'pg', que gerencia conexões com o PostgreSQL
const { Pool } = require('pg');
require('dotenv').config();

// Na nuvem, a conexão vem de DATABASE_URL e exige conexão segura (SSL).
// Localmente, usa os dados separados do .env (DB_HOST, DB_PORT, ...).
const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    })
  : new Pool({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
    });

// Exporta o pool para que outros arquivos (como as rotas) possam usá-lo
module.exports = pool;