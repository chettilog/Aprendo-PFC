// Termos de Uso e Política de Privacidade (públicos, lidos da pasta documentos/)
const express = require('express');
const fs = require('fs');
const path = require('path');

const router = express.Router();
const PASTA_DOCUMENTOS = path.join(__dirname, '..', '..', 'documentos');

function enviarDocumento(res, arquivo, mensagemErro) {
  try {
    const conteudo = fs.readFileSync(path.join(PASTA_DOCUMENTOS, arquivo), 'utf-8');
    res.json({ versao: '1.0', conteudo: conteudo });
  } catch (err) {
    res.status(500).json({ error: mensagemErro, detalhes: err.message });
  }
}

router.get('/termos', (req, res) => {
  enviarDocumento(res, 'termos-de-uso-v1.md', 'Erro ao carregar Termos de Uso');
});

router.get('/politica', (req, res) => {
  enviarDocumento(res, 'politica-de-privacidade-v1.md', 'Erro ao carregar Política de Privacidade');
});

module.exports = router;
