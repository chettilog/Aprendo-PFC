// Testes das rotas da API com o banco simulado (não precisa de PostgreSQL rodando)
process.env.JWT_SECRET = 'segredo-de-teste';
delete process.env.GEMINI_API_KEY;

jest.mock('../src/config/banco', () => ({ query: jest.fn(), connect: jest.fn() }));
const pool = require('../src/config/banco');
const request = require('supertest');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const app = require('../src/app');

const token = jwt.sign({ id: 7, email: 'aluno@teste.com' }, process.env.JWT_SECRET);
const auth = { Authorization: `Bearer ${token}` };

// Responde cada consulta de acordo com um trecho do SQL
function banco(respostas) {
  pool.query.mockImplementation(async (sql) => {
    for (const [trecho, resposta] of respostas) {
      if (sql.includes(trecho)) {
        if (resposta instanceof Error) throw resposta;
        return resposta;
      }
    }
    return { rows: [] };
  });
}

beforeEach(() => {
  jest.clearAllMocks();
  jest.spyOn(console, 'error').mockImplementation(() => {});
});

describe('status', () => {
  test('GET / responde', async () => {
    const r = await request(app).get('/');
    expect(r.status).toBe(200);
  });
  test('GET /test-db com banco fora do ar', async () => {
    banco([['SELECT NOW', new Error('sem conexão')]]);
    expect((await request(app).get('/test-db')).status).toBe(500);
  });
});

describe('cadastro (RF01)', () => {
  test('exige aceite dos termos (LGPD)', async () => {
    const r = await request(app).post('/cadastro').send({ nome: 'Ana', email: 'a@a.com', senha: '123456' });
    expect(r.status).toBe(400);
    expect(r.body.error).toMatch(/Termos/);
  });
  test('exige a declaração de idade mínima (LGPD, Art. 14)', async () => {
    const r = await request(app).post('/cadastro')
      .send({ nome: 'Ana', email: 'a@a.com', senha: '123456', aceitouTermos: true });
    expect(r.status).toBe(400);
    expect(r.body.error).toMatch(/12 anos/);
  });
  test('valida os campos', async () => {
    const r = await request(app).post('/cadastro').send({ nome: 'A', email: 'a@a.com', senha: '123456', aceitouTermos: true, idadeMinima: true });
    expect(r.status).toBe(400);
  });
  test('cria a conta e guarda a senha com hash', async () => {
    banco([['INSERT INTO usuarios', { rows: [{ id: 1, nome: 'Ana', email: 'a@a.com' }] }]]);
    const r = await request(app).post('/cadastro')
      .send({ nome: ' Ana ', email: 'a@a.com', senha: '123456', aceitouTermos: true, idadeMinima: true });
    expect(r.status).toBe(201);
    const params = pool.query.mock.calls.find(c => c[0].includes('INSERT INTO usuarios'))[1];
    expect(params[0]).toBe('Ana');
    expect(params[2]).not.toBe('123456');
    expect(await bcrypt.compare('123456', params[2])).toBe(true);
    // o log do cadastro não guarda o e-mail
    const log = pool.query.mock.calls.find(c => c[0].includes('INSERT INTO logs'))[1];
    expect(log[2]).not.toContain('a@a.com');
  });
  test('e-mail repetido devolve 409', async () => {
    banco([['INSERT INTO usuarios', Object.assign(new Error('dup'), { code: '23505' })]]);
    const r = await request(app).post('/cadastro')
      .send({ nome: 'Ana', email: 'a@a.com', senha: '123456', aceitouTermos: true, idadeMinima: true });
    expect(r.status).toBe(409);
    const log = pool.query.mock.calls.find(c => c[0].includes('INSERT INTO logs'))[1];
    expect(log[2]).toContain('a***@a.com');
  });
});

describe('login (RF02)', () => {
  test('campos obrigatórios', async () => {
    expect((await request(app).post('/login').send({})).status).toBe(400);
  });
  test('e-mail inexistente e senha errada dão a mesma mensagem', async () => {
    const hash = await bcrypt.hash('123456', 4);
    banco([['FROM usuarios WHERE email', { rows: [] }]]);
    const r1 = await request(app).post('/login').send({ email: 'x@x.com', senha: '123456' });
    banco([['FROM usuarios WHERE email', { rows: [{ id: 1, nome: 'Ana', email: 'a@a.com', senha: hash }] }]]);
    const r2 = await request(app).post('/login').send({ email: 'a@a.com', senha: 'errada' });
    expect(r1.status).toBe(401);
    expect(r2.status).toBe(401);
    expect(r1.body.error).toBe(r2.body.error);
  });
  test('tentativa com e-mail desconhecido grava o e-mail mascarado no log', async () => {
    banco([['FROM usuarios WHERE email', { rows: [] }]]);
    await request(app).post('/login').send({ email: 'joao.silva@email.com', senha: '123456' });
    const log = pool.query.mock.calls.find(c => c[0].includes('INSERT INTO logs'))[1];
    expect(log[2]).toContain('j***@email.com');
    expect(log[2]).not.toContain('joao.silva');
  });
  test('login certo devolve um token JWT', async () => {
    const hash = await bcrypt.hash('123456', 4);
    banco([['FROM usuarios WHERE email', { rows: [{ id: 1, nome: 'Ana', email: 'a@a.com', senha: hash }] }]]);
    const r = await request(app).post('/login').send({ email: 'a@a.com', senha: '123456' });
    expect(r.status).toBe(200);
    const conteudoDoToken = jwt.verify(r.body.token, process.env.JWT_SECRET);
    expect(conteudoDoToken.id).toBe(1);
    expect(conteudoDoToken).not.toHaveProperty('email'); // nenhum dado pessoal no token
  });
});

describe('token e perfil de acesso', () => {
  test('sem token: 401', async () => {
    expect((await request(app).get('/perfil')).status).toBe(401);
  });
  test('token inválido: 403', async () => {
    expect((await request(app).get('/perfil').set('Authorization', 'Bearer lixo')).status).toBe(403);
  });
  test('perfil do usuário logado', async () => {
    banco([['FROM usuarios WHERE id', { rows: [{ id: 7, nome: 'Ana' }] }]]);
    const r = await request(app).get('/perfil').set(auth);
    expect(r.status).toBe(200);
    expect(r.body.usuario.nome).toBe('Ana');
  });
  test('aluno não acessa /logs', async () => {
    banco([['SELECT perfil', { rows: [{ perfil: 'aluno' }] }]]);
    expect((await request(app).get('/logs').set(auth)).status).toBe(403);
  });
  test('admin acessa /logs', async () => {
    banco([['SELECT perfil', { rows: [{ perfil: 'admin' }] }], ['FROM logs', { rows: [{ id: 1 }] }]]);
    const r = await request(app).get('/logs').set(auth);
    expect(r.status).toBe(200);
    expect(r.body.logs).toHaveLength(1);
  });
  test('excluir a própria conta (LGPD)', async () => {
    banco([['SELECT email', { rows: [{ email: 'a@a.com' }] }]]);
    const r = await request(app).delete('/minha-conta').set(auth);
    expect(r.status).toBe(200);
    expect(pool.query.mock.calls.some(c => c[0].startsWith('DELETE FROM usuarios'))).toBe(true);
    // o e-mail é mascarado nos logs antigos e não aparece no log da exclusão
    const limpeza = pool.query.mock.calls.find(c => c[0].includes('UPDATE logs'));
    expect(limpeza[1]).toEqual(['a@a.com', 'a***@a.com']);
    const logs = pool.query.mock.calls.filter(c => c[0].includes('INSERT INTO logs'));
    expect(logs.every(c => !String(c[1][2]).includes('a@a.com'))).toBe(true);
  });
});

describe('documentos', () => {
  test('termos e política são públicos', async () => {
    expect((await request(app).get('/termos')).status).toBe(200);
    expect((await request(app).get('/politica')).body.conteudo).toMatch(/Privacidade/);
  });
});

describe('trilhas e aulas (RF04 e RF05)', () => {
  test('lista trilhas', async () => {
    banco([['FROM trilhas t', { rows: [{ id: 1, nome: 'Funções' }] }]]);
    expect((await request(app).get('/trilhas').set(auth)).body.trilhas).toHaveLength(1);
  });
  test('id inválido: 400', async () => {
    expect((await request(app).get('/trilhas/abc/aulas').set(auth)).status).toBe(400);
    expect((await request(app).get('/aulas/0').set(auth)).status).toBe(400);
  });
  test('trilha inexistente: 404', async () => {
    banco([]);
    expect((await request(app).get('/trilhas/99/aulas').set(auth)).status).toBe(404);
  });
  test('aulas com concluida, parcial e melhor nota', async () => {
    banco([
      ['FROM trilhas WHERE id', { rows: [{ id: 1 }] }],
      ['FROM aulas a', { rows: [
        { id: 1, concluida: true, tem_parcial: true, melhor_nota: 90 },
        { id: 2, concluida: false, tem_parcial: true, melhor_nota: 55 },
        { id: 3, concluida: false, tem_parcial: false, melhor_nota: null },
      ] }],
    ]);
    const r = await request(app).get('/trilhas/1/aulas').set(auth);
    expect(r.body.aulas.map(a => a.concluida)).toEqual([true, false, false]);
    // só é "parcial" quem acertou parte e ainda não concluiu
    expect(r.body.aulas.map(a => a.parcial)).toEqual([false, true, false]);
    expect(r.body.aulas.map(a => a.melhor_nota)).toEqual([90, 55, null]);
    expect(r.body.aulas[0]).not.toHaveProperty('tem_parcial');
  });
  test('conteúdo da aula', async () => {
    banco([['FROM aulas a', { rows: [{ id: 1, titulo: 'Funções' }] }]]);
    expect((await request(app).get('/aulas/1').set(auth)).body.aula.titulo).toBe('Funções');
  });
});

describe('produção, avaliação e XP (RF06, RF07 e RF08)', () => {
  const aula = {
    id: 1, titulo: 'O que é uma função', conteudo: 'Uma função relaciona valores.',
    palavras_chave: 'função,domínio,contradomínio,entrada,saída',
  };
  const BOA = 'A função é uma regra que liga cada entrada do domínio a uma única saída no contradomínio.';

  function transacao(xpJaRecebido) {
    const client = {
      query: jest.fn(async (sql) => {
        if (sql.includes('INSERT INTO producoes')) return { rows: [{ id: 10, aula_id: 1 }] };
        if (sql.includes('AND aula_id')) return { rows: [{ total: xpJaRecebido }] };
        if (sql.includes('SUM(valor)')) return { rows: [{ total: 120 }] };
        return { rows: [] };
      }),
      release: jest.fn(),
    };
    pool.connect.mockResolvedValue(client);
    return client;
  }

  test('texto curto: 400', async () => {
    const r = await request(app).post('/aulas/1/producoes').set(auth).send({ conteudo: 'curto' });
    expect(r.status).toBe(400);
  });
  test('aula inexistente: 404', async () => {
    banco([]);
    const r = await request(app).post('/aulas/1/producoes').set(auth).send({ conteudo: BOA });
    expect(r.status).toBe(404);
  });
  test('resposta certa ganha 50 XP', async () => {
    banco([['FROM aulas a', { rows: [aula] }]]);
    const client = transacao(0);
    const r = await request(app).post('/aulas/1/producoes').set(auth).send({ conteudo: BOA });
    expect(r.status).toBe(201);
    expect(r.body.feedback).toMatchObject({ resultado: 'suficiente', nota: 100, avaliador: 'regras' });
    expect(r.body.xp.ganho).toBe(50);
    expect(client.query).toHaveBeenCalledWith('COMMIT');
    expect(client.release).toHaveBeenCalled();
  });
  test('quem já tinha 25 XP (parcial) ganha só mais 25', async () => {
    banco([['FROM aulas a', { rows: [aula] }]]);
    transacao(25);
    const r = await request(app).post('/aulas/1/producoes').set(auth).send({ conteudo: BOA });
    expect(r.body.xp).toMatchObject({ ganho: 25, aula: 50 });
  });
  test('texto sem sentido: nota 0 e nenhum XP', async () => {
    banco([['FROM aulas a', { rows: [aula] }]]);
    transacao(0);
    const r = await request(app).post('/aulas/1/producoes').set(auth)
      .send({ conteudo: 'função domínio contradomínio entrada saída asdkjasd qweqwe zxczxc fdgdfg' });
    expect(r.body.feedback).toMatchObject({ resultado: 'insuficiente', nota: 0, avaliador: 'filtro' });
    expect(r.body.xp.ganho).toBe(0);
  });
  test('erro no meio da transação desfaz tudo (ROLLBACK)', async () => {
    banco([['FROM aulas a', { rows: [aula] }]]);
    const client = transacao(0);
    client.query.mockImplementation(async (sql) => {
      if (sql.includes('INSERT INTO feedbacks')) throw new Error('falhou');
      return { rows: [{ id: 10 }] };
    });
    const r = await request(app).post('/aulas/1/producoes').set(auth).send({ conteudo: BOA });
    expect(r.status).toBe(500);
    expect(client.query).toHaveBeenCalledWith('ROLLBACK');
  });
  test('histórico de produções', async () => {
    banco([['FROM producoes p', { rows: [{ id: 1, nota: 80 }] }]]);
    expect((await request(app).get('/aulas/1/producoes').set(auth)).body.producoes[0].nota).toBe(80);
  });
});

describe('dashboard (RF13)', () => {
  test('calcula nível, percentual, dias seguidos e próxima aula', async () => {
    banco([
      ['SELECT nome FROM usuarios', { rows: [{ nome: 'Ana' }] }],
      ['FROM movimentacoes_xp WHERE usuario_id = $1', { rows: [{ total: 150 }] }],
      ['AS nota_media', { rows: [{ total: 4, nota_media: 72 }] }],
      ['FROM trilhas t', { rows: [{ id: 1, total_aulas: 4, aulas_concluidas: 1 }] }],
      ['generate_series', { rows: [{ dia: '2026-11-14', xp: 50 }] }],
      ['AS dia_estudado', { rows: [
        { dia_estudado: '2026-11-14', hoje: '2026-11-14' },
        { dia_estudado: '2026-11-13', hoje: '2026-11-14' },
      ] }],
      ['LIMIT 3', { rows: [{ aula_id: 1, aula_titulo: 'Funções', nota: 80, resultado: 'suficiente' }] }],
      ['AS trilha_nome', { rows: [
        { id: 1, titulo: 'Aula 1', trilha_id: 1, trilha_nome: 'Funções', concluida: true },
        { id: 2, titulo: 'Aula 2', trilha_id: 1, trilha_nome: 'Funções', concluida: false },
      ] }],
    ]);
    const r = await request(app).get('/dashboard').set(auth);
    expect(r.status).toBe(200);
    expect(r.body.dashboard).toMatchObject({
      nome: 'Ana', xp_total: 150, nivel: 2, xp_no_nivel: 50, xp_para_proximo_nivel: 50,
      producoes_enviadas: 4, nota_media: 72, dias_seguidos: 2, aulas_concluidas: 1,
    });
    expect(r.body.dashboard.trilhas[0].percentual).toBe(25);
    expect(r.body.dashboard.ultimas_producoes).toHaveLength(1);
    expect(r.body.dashboard.proxima_aula).toMatchObject({ id: 2, trilha_id: 1 });
  });

  test('aluno novo, sem nenhum dado, não quebra', async () => {
    banco([]);
    const r = await request(app).get('/dashboard').set(auth);
    expect(r.status).toBe(200);
    expect(r.body.dashboard).toMatchObject({
      nome: null, xp_total: 0, nivel: 1, xp_para_proximo_nivel: 100,
      producoes_enviadas: 0, nota_media: null, dias_seguidos: 0, proxima_aula: null,
    });
  });

  test('erro no banco: 500', async () => {
    banco([['SELECT nome FROM usuarios', new Error('sem conexão')]]);
    expect((await request(app).get('/dashboard').set(auth)).status).toBe(500);
  });
});
