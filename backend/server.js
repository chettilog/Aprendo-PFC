// Importa o Express, o framework que gerencia nossas rotas
const express = require('express');
// Importa o CORS, que permite o frontend Flutter conversar com essa API
const cors = require('cors');
// Carrega variáveis de ambiente do arquivo .env
require('dotenv').config();

const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('./db');

// Cria a aplicação Express
const app = express();

// Middleware: permite que o servidor entenda requisições com corpo em JSON
app.use(express.json());
// Middleware: libera o acesso de outras origens (o Flutter Web, por exemplo)
app.use(cors());

// Define a porta que o servidor vai escutar (usa a do .env, ou 3000 como padrão)
const PORT = process.env.PORT || 3000;

// Middleware: valida o token JWT em rotas protegidas
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

// Função utilitária: registra um evento na tabela de logs
async function registrarLog(usuarioId, acao, detalhes, ip, sucesso = true) {
  try {
    await pool.query(
      'INSERT INTO logs (usuario_id, acao, detalhes, ip, sucesso) VALUES ($1, $2, $3, $4, $5)',
      [usuarioId, acao, detalhes, ip, sucesso]
    );
  } catch (err) {
    // Se o log falhar, não quebra a aplicação — só imprime no console
    console.error('Erro ao registrar log:', err.message);
  }
}

// Middleware: permite acesso apenas a usuários com um dos perfis informados
// O perfil é consultado no banco a cada requisição (não confia só no token)
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

// Rota de teste simples
app.get('/', (req, res) => {
  res.json({ message: 'API do Aprendo está funcionando!' });
});

// Rota de teste do banco
app.get('/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({ message: 'Conexão com o banco funcionando!', horario: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao conectar com o banco', detalhes: err.message });
  }
});

// Rota de cadastro de usuário
app.post('/cadastro', async (req, res) => {
  try {
    const { nome, email, senha, aceitouTermos } = req.body;

    if (!nome || !email || !senha) {
      return res.status(400).json({ error: 'Nome, e-mail e senha são obrigatórios' });
    }

    // Validação LGPD: exige aceite explícito dos termos antes de criar conta
    if (!aceitouTermos) {
      return res.status(400).json({ 
        error: 'É necessário aceitar os Termos de Uso e a Política de Privacidade' 
      });
    }

    const senhaCriptografada = await bcrypt.hash(senha, 10);

    // Versão atual dos documentos aceitos (atualizar quando os termos mudarem)
    const versaoTermos = '1.0';

    const result = await pool.query(
      `INSERT INTO usuarios (nome, email, senha, termos_aceitos_em, termos_versao) 
       VALUES ($1, $2, $3, NOW(), $4) 
       RETURNING id, nome, email, termos_aceitos_em, termos_versao`,
      [nome, email, senhaCriptografada, versaoTermos]
    );

    // Registra log de cadastro bem-sucedido
    await registrarLog(
      result.rows[0].id,
      'cadastro',
      `Novo usuário: ${email} (termos v${versaoTermos})`,
      req.ip,
      true
    );

    res.status(201).json({ 
      message: 'Usuário cadastrado com sucesso!', 
      usuario: result.rows[0] 
    });
  } catch (err) {
    if (err.code === '23505') {
      await registrarLog(
        null,
        'cadastro_falha',
        `Email já cadastrado: ${req.body.email}`,
        req.ip,
        false
      );
      return res.status(409).json({ error: 'Este e-mail já está cadastrado' });
    }
    res.status(500).json({ error: 'Erro ao cadastrar usuário', detalhes: err.message });
  }
});
        // Registra log de cadastro bem-sucedido

// Rota de login
app.post('/login', async (req, res) => {
  try {
    const { email, senha } = req.body;

    if (!email || !senha) {
      return res.status(400).json({ error: 'E-mail e senha são obrigatórios' });
    }

    const result = await pool.query(
      'SELECT id, nome, email, senha FROM usuarios WHERE email = $1',
      [email]
    );

        if (result.rows.length === 0) {
      // Registra tentativa de login com email inexistente
      await registrarLog(
        null,
        'login_falha',
        `Email não cadastrado: ${email}`,
        req.ip,
        false
      );
      return res.status(401).json({ error: 'E-mail ou senha inválidos' });
    }

    const usuario = result.rows[0];

    const senhaCorreta = await bcrypt.compare(senha, usuario.senha);

        if (!senhaCorreta) {
      // Registra tentativa de login com senha errada
      await registrarLog(
        usuario.id,
        'login_falha',
        `Senha incorreta`,
        req.ip,
        false
      );
      return res.status(401).json({ error: 'E-mail ou senha inválidos' });
    }

    // Login bem-sucedido: gera um token JWT
    const token = jwt.sign(
      {
        id: usuario.id,
        email: usuario.email,
      },
      process.env.JWT_SECRET,
      { expiresIn: '2h' }
    );

        // Registra log de login bem-sucedido
    await registrarLog(
      usuario.id,
      'login',
      `Login realizado`,
      req.ip,
      true
    );

    res.json({
      message: 'Login realizado com sucesso!',
      token: token,
      usuario: {
        id: usuario.id,
        nome: usuario.nome,
        email: usuario.email,
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao realizar login', detalhes: err.message });
  }
});

// Rota protegida: retorna os dados do usuário logado
app.get('/perfil', verificarToken, async (req, res) => {
  try {
    const result = await pool.query(
            'SELECT id, nome, email, perfil, criado_em FROM usuarios WHERE id = $1',
      [req.usuario.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

       // Registra log de acesso ao perfil
    await registrarLog(
      req.usuario.id,
      'acesso_perfil',
      `Consulta ao próprio perfil`,
      req.ip,
      true
    );

    res.json({ usuario: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao buscar perfil', detalhes: err.message });
  }
});
// Rota protegida: permite o usuário logado excluir a própria conta (LGPD - direito à exclusão)
app.delete('/minha-conta', verificarToken, async (req, res) => {
  try {
    const usuarioId = req.usuario.id;

    // Busca dados do usuário antes de apagar (pra usar no log)
    const busca = await pool.query(
      'SELECT email FROM usuarios WHERE id = $1',
      [usuarioId]
    );

    if (busca.rows.length === 0) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    const emailUsuario = busca.rows[0].email;

    // Apaga o usuário. Graças ao ON DELETE SET NULL na tabela logs,
    // os logs dele permanecem para auditoria, mas com usuario_id = NULL
    await pool.query('DELETE FROM usuarios WHERE id = $1', [usuarioId]);

    // Registra o evento de exclusão (usuario_id = null porque o usuário não existe mais)
    await registrarLog(
      null,
      'exclusao_conta',
      `Conta excluída pelo próprio titular: ${emailUsuario}`,
      req.ip,
      true
    );

    res.json({ message: 'Sua conta foi excluída com sucesso. Sentimos sua falta!' });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao excluir conta', detalhes: err.message });
  }
});

// Rota protegida: retorna os logs de auditoria
app.get('/logs', verificarToken, exigirPerfil('admin'), async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT l.id, l.usuario_id, u.nome as usuario_nome, l.acao, l.detalhes, 
              l.ip, l.sucesso, l.criado_em
       FROM logs l
       LEFT JOIN usuarios u ON u.id = l.usuario_id
       ORDER BY l.criado_em DESC
       LIMIT 100`
    );

    res.json({ logs: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao buscar logs', detalhes: err.message });
  }
});

// Rota pública: retorna o texto dos Termos de Uso
app.get('/termos', (req, res) => {
  try {
    const caminho = path.join(__dirname, 'documentos', 'termos-de-uso-v1.md');
    const conteudo = fs.readFileSync(caminho, 'utf-8');
    res.json({ versao: '1.0', conteudo: conteudo });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao carregar Termos de Uso', detalhes: err.message });
  }
});

// Rota pública: retorna o texto da Política de Privacidade
app.get('/politica', (req, res) => {
  try {
    const caminho = path.join(__dirname, 'documentos', 'politica-de-privacidade-v1.md');
    const conteudo = fs.readFileSync(caminho, 'utf-8');
    res.json({ versao: '1.0', conteudo: conteudo });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao carregar Política de Privacidade', detalhes: err.message });
  }
});
// Rota protegidaverificarToken: consulta a API da Wikipedia (proxy - protege o IP do aluno)
// A chamada é feita pelo servidor, Wikipedia recebe apenas o IP do backend
app.get('/wiki/:topico', verificarToken, async (req, res) => {
  try {
    const topico = req.params.topico;

    if (!topico || topico.trim().length === 0) {
      return res.status(400).json({ error: 'Tópico não informado' });
    }

    // Codifica o tópico pra URL (ex: "São Paulo" vira "S%C3%A3o%20Paulo")
    const topicoCodificado = encodeURIComponent(topico);
    const urlWiki = `https://pt.wikipedia.org/api/rest_v1/page/summary/${topicoCodificado}`;

    // Faz a chamada pra Wikipedia (sem enviar dados pessoais do usuário)
    const resposta = await fetch(urlWiki);

    if (resposta.status === 404) {
      // Registra tentativa de busca sem resultado (útil pra melhorar o conteúdo depois)
      await registrarLog(
        req.usuario.id,
        'busca_wiki_sem_resultado',
        `Termo pesquisado: ${topico}`,
        req.ip,
        false
      );
      return res.status(404).json({ error: 'Tópico não encontrado na Wikipedia' });
    }

    if (!resposta.ok) {
      return res.status(502).json({ error: 'Erro ao consultar a Wikipedia' });
    }

    const dados = await resposta.json();

    // Registra a consulta bem-sucedida (auditoria + estatística de uso)
    await registrarLog(
      req.usuario.id,
      'busca_wiki',
      `Termo pesquisado: ${dados.title}`,
      req.ip,
      true
    );

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

// Inicia o servidor
app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}`);
});