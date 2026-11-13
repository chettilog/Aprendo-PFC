// Middlewares de segurança: quem está logado (token) e o que pode acessar (perfil)
const jwt = require('jsonwebtoken');
const pool = require('../config/banco');
const { registrarLog } = require('../servicos/logs');

// Valida o token JWT em rotas protegidas
function verificarToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Token não fornecido' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(403).json({ error: 'Token inválido ou expirado' });
    }
    req.usuario = decoded;
    next();
  });
}

// Permite acesso apenas a usuários com um dos perfis informados
// O perfil é consultado no banco a cada requisição
function exigirPerfil(...perfisPermitidos) {
  return async (req, res, next) => {
    try {
      const result = await pool.query(
        'SELECT perfil FROM usuarios WHERE id = $1',
        [req.usuario.id]
      );

      if (result.rows.length === 0) {
        return res.status(401).json({ error: 'Usuário não encontrado' });
      }

      const perfil = result.rows[0].perfil;

      if (!perfisPermitidos.includes(perfil)) {
        // Registra a tentativa de acesso negado (auditoria)
        await registrarLog(
          req.usuario.id,
          'acesso_negado',
          `Tentativa de acesso a ${req.originalUrl} com perfil ${perfil}`,
          req.ip,
          false
        );
        return res.status(403).json({ error: 'Acesso negado: permissão insuficiente' });
      }

      req.usuario.perfil = perfil;
      next();
    } catch (err) {
      res.status(500).json({ error: 'Erro ao verificar permissões', detalhes: err.message });
    }
  };
}

module.exports = { verificarToken, exigirPerfil };
