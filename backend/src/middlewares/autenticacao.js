// Middlewares de segurança: quem está logado (token) e o que pode acessar (perfil)
const jwt = require('jsonwebtoken');
const { erroInterno } = require('../utils/erros');
const pool = require('../config/banco');
const { registrarLog } = require('../servicos/logs');

// Valida o token JWT em rotas protegidas.
// Além da assinatura e da validade (2h), confere no banco se a conta ainda existe e se a senha
// não foi trocada depois que o token foi emitido: trocar a senha encerra as sessões antigas.
async function verificarToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Token não fornecido' });
  }

  let decoded;
  try {
    decoded = jwt.verify(token, process.env.JWT_SECRET, { algorithms: ['HS256'] });
  } catch {
    return res.status(403).json({ error: 'Token inválido ou expirado' });
  }

  try {
    const result = await pool.query('SELECT senha_alterada_em FROM usuarios WHERE id = $1', [decoded.id]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Sessão inválida: conta não encontrada' });
    }
    const alterada = result.rows[0].senha_alterada_em;
    // iat = momento (em segundos) em que o token foi emitido
    if (alterada && decoded.iat < Math.floor(new Date(alterada).getTime() / 1000)) {
      return res.status(401).json({ error: 'Sessão encerrada porque a senha foi alterada. Entre novamente.' });
    }
  } catch (err) {
    return erroInterno(res, err, 'Erro ao verificar a sessão');
  }

  req.usuario = decoded;
  next();
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
      erroInterno(res, err, 'Erro ao verificar permissões');
    }
  };
}

module.exports = { verificarToken, exigirPerfil };
