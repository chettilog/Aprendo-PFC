// Avaliação da produção do aluno (RF07)
const PALAVRAS_MIN = 2;     // palavras-chave da aula que a produção deve citar

// Remove acentos e deixa em minúsculas, para comparar os textos
function normalizar(texto) {
  return texto.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
}

// Avalia a produção: suficiente se citar ao menos PALAVRAS_MIN palavras-chave da aula
function avaliarProducao(texto, palavrasChave) {
  const lista = (palavrasChave || '').split(',').map(p => p.trim()).filter(Boolean);
  const alvo = normalizar(texto);
  const citadas = lista.filter(p => alvo.includes(normalizar(p)));
  const faltantes = lista.filter(p => !citadas.includes(p));
  const suficiente = citadas.length >= Math.min(PALAVRAS_MIN, lista.length);

  let comentario;
  if (!suficiente) {
    comentario = `Tente explicar também: ${faltantes.join(', ')}.`;
  } else if (citadas.length > 0) {
    comentario = `Boa explicação! Você citou: ${citadas.join(', ')}.`;
  } else {
    comentario = 'Produção registrada com sucesso.';
  }
  return {
    resultado: suficiente ? 'suficiente' : 'insuficiente',
    comentario: comentario.slice(0, 255)
  };
}

module.exports = { PALAVRAS_MIN, normalizar, avaliarProducao };
