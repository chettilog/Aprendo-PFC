// Resposta padrão para erro interno (500).
// O detalhe técnico (mensagem do banco, por exemplo) fica só no log do servidor:
// devolver isso ao cliente revelaria nomes de tabelas e outros detalhes internos.
function erroInterno(res, err, mensagem) {
  console.error(`[erro] ${mensagem}:`, err && err.message);
  return res.status(500).json({ error: mensagem });
}

module.exports = { erroInterno };
