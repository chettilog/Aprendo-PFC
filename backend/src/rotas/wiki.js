// Busca na Wikipedia feita pelo servidor (proxy): a Wikipedia recebe só o IP do backend,
// nunca o do aluno (minimização de dados - LGPD)
const express = require('express');
const { verificarToken } = require('../middlewares/autenticacao');
const { registrarLog } = require('../servicos/logs');

const router = express.Router();

router.get('/wiki/:topico', verificarToken, async (req, res) => {
  try {
    const topico = req.params.topico;

    if (!topico || topico.trim().length === 0) {
      return res.status(400).json({ error: 'Tópico não informado' });
    }

    // Codifica o tópico pra URL (ex: "São Paulo" vira "S%C3%A3o%20Paulo")
    const urlWiki = `https://pt.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(topico)}`;
    const resposta = await fetch(urlWiki);

    if (resposta.status === 404) {
      await registrarLog(req.usuario.id, 'busca_wiki_sem_resultado', `Termo pesquisado: ${topico}`, req.ip, false);
      return res.status(404).json({ error: 'Tópico não encontrado na Wikipedia' });
    }

    if (!resposta.ok) {
      return res.status(502).json({ error: 'Erro ao consultar a Wikipedia' });
    }

    const dados = await resposta.json();

    await registrarLog(req.usuario.id, 'busca_wiki', `Termo pesquisado: ${dados.title}`, req.ip, true);

    // Retorna apenas os campos que o frontend precisa (minimização)
    res.json({
      titulo: dados.title,
      descricao: dados.description || null,
      resumo: dados.extract,
      link: dados.content_urls?.desktop?.page || null,
      imagem: dados.thumbnail?.source || null,
    });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao buscar tópico', detalhes: err.message });
  }
});

module.exports = router;
