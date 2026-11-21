// Termos de Uso e Política de Privacidade (públicos, lidos da pasta documentos/)
const express = require('express');
const { erroInterno } = require('../utils/erros');
const fs = require('fs');
const path = require('path');

const router = express.Router();
const PASTA_DOCUMENTOS = path.join(__dirname, '..', '..', 'documentos');

function enviarDocumento(res, arquivo, versao, mensagemErro) {
  try {
    const conteudo = fs.readFileSync(path.join(PASTA_DOCUMENTOS, arquivo), 'utf-8');
    res.json({ versao, conteudo });
  } catch (err) {
    erroInterno(res, err, mensagemErro);
  }
}

router.get('/termos', (req, res) => {
  enviarDocumento(res, 'termos-de-uso-v1.md', '1.1', 'Erro ao carregar Termos de Uso');
});

router.get('/politica', (req, res) => {
  enviarDocumento(res, 'politica-de-privacidade-v1.md', '1.5', 'Erro ao carregar Política de Privacidade');
});

module.exports = router;
