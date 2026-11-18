// Limite de tentativas: bloqueia quem faz pedidos demais em pouco tempo.
// Protege contra força bruta de senha, contra quem tenta adivinhar códigos do ranking
// e contra o abuso do envio de explicações (cada envio consome a cota da IA).
// Os contadores ficam na memória do servidor: o Aprendo roda em uma única instância.
const { registrarLog } = require('../servicos/logs');

const contadores = new Map(); // "nome:chave" -> { contagem, inicio, avisado }

// De 10 em 10 minutos, apaga os contadores cuja janela já acabou
const limpeza = setInterval(() => {
  const agora = Date.now();
  for (const [id, c] of contadores) {
    if (agora - c.inicio >= c.janelaMs) contadores.delete(id);
  }
}, 10 * 60 * 1000);
limpeza.unref(); // não impede o processo de encerrar

/**
 * Cria um middleware de limite.
 * nome: identifica o limite nos logs
 * janelaMs / maximo: no máximo `maximo` pedidos a cada `janelaMs` milissegundos
 * chave(req): de quem é a contagem (IP, e-mail ou id do usuário)
 * contarSoFalhas: se true, pedidos que deram certo não contam (o aluno que acerta a senha não é punido)
 */
function limitarTentativas({ nome, janelaMs, maximo, chave = (req) => req.ip, contarSoFalhas = false, mensagem }) {
  return (req, res, next) => {
    // Nos testes automáticos o limite fica desligado, exceto nos testes do próprio limite
    if (process.env.NODE_ENV === 'test' && !process.env.TESTAR_LIMITES) return next();

    const valorChave = chave(req);
    if (valorChave === undefined || valorChave === null || valorChave === '') return next();

    const agora = Date.now();
    const id = `${nome}:${valorChave}`;
    let c = contadores.get(id);
    if (!c || agora - c.inicio >= janelaMs) {
      c = { contagem: 0, inicio: agora, janelaMs, avisado: false };
      contadores.set(id, c);
    }

    if (c.contagem >= maximo) {
      res.set('Retry-After', String(Math.ceil((c.inicio + janelaMs - agora) / 1000)));
      if (!c.avisado) {
        // registra só o primeiro bloqueio de cada janela, para não encher os logs
        c.avisado = true;
        registrarLog(req.usuario ? req.usuario.id : null, 'limite_excedido',
          `Limite de tentativas atingido em: ${nome}`, req.ip, false);
      }
      return res.status(429).json({
        error: mensagem || 'Muitas tentativas em pouco tempo. Aguarde alguns minutos e tente de novo.',
      });
    }

    // Conta antes de responder (assim, vários pedidos ao mesmo tempo não escapam do limite);
    // se só as falhas contam, devolve a contagem quando o pedido dá certo
    c.contagem++;
    if (contarSoFalhas) {
      res.on('finish', () => {
        if (res.statusCode < 400 && c.contagem > 0) c.contagem--;
      });
    }
    next();
  };
}

const MINUTO = 60 * 1000;
const emailDoCorpo = (req) => {
  const email = req.body && req.body.email;
  return typeof email === 'string' ? email.trim().toLowerCase() : null;
};
const idDoUsuario = (req) => (req.usuario ? req.usuario.id : null);

// Os limites por IP são folgados porque, numa escola, vários alunos saem pelo mesmo IP.
// A proteção forte contra força bruta é a do limite por e-mail.
const limites = {
  loginPorIp: limitarTentativas({ nome: 'login-ip', janelaMs: 15 * MINUTO, maximo: 30, contarSoFalhas: true }),
  loginPorEmail: limitarTentativas({
    nome: 'login-email', janelaMs: 15 * MINUTO, maximo: 5, chave: emailDoCorpo, contarSoFalhas: true,
    mensagem: 'Muitas tentativas de login nesta conta. Aguarde 15 minutos e tente de novo.',
  }),
  cadastro: limitarTentativas({ nome: 'cadastro', janelaMs: 60 * MINUTO, maximo: 30 }),
  producoes: limitarTentativas({
    nome: 'producoes', janelaMs: 10 * MINUTO, maximo: 20, chave: idDoUsuario,
    mensagem: 'Você enviou muitas explicações em pouco tempo. Aguarde alguns minutos.',
  }),
  colegas: limitarTentativas({
    nome: 'colegas', janelaMs: 15 * MINUTO, maximo: 10, chave: idDoUsuario, contarSoFalhas: true,
    mensagem: 'Muitos códigos inválidos. Aguarde 15 minutos e tente de novo.',
  }),
  senha: limitarTentativas({ nome: 'senha', janelaMs: 15 * MINUTO, maximo: 5, chave: idDoUsuario, contarSoFalhas: true }),
};

function limparContadores() { contadores.clear(); }

module.exports = { limitarTentativas, limites, limparContadores };
