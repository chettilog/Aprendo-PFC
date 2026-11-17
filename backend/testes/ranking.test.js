// Testes do ranking entre colegas: regras (servicos/ranking.js) e rotas (rotas/ranking.js)
process.env.JWT_SECRET = 'segredo-de-teste';
jest.mock('../src/config/banco', () => ({ query: jest.fn(), connect: jest.fn() }));
const pool = require('../src/config/banco');
const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../src/app');
const {
  primeiroNome, formatarCodigo, interpretarCodigo, nomeConfere, montarRanking, montarRankingGeral,
} = require('../src/servicos/ranking');
const { calcularNivel } = require('../src/servicos/xp');

const auth = { Authorization: `Bearer ${jwt.sign({ id: 7 }, process.env.JWT_SECRET)}` };

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

describe('regras do código', () => {
  test('primeiro nome e código formatado', () => {
    expect(primeiroNome('  João Pedro Marchetti ')).toBe('João');
    expect(primeiroNome(null)).toBe('');
    expect(formatarCodigo('João Pedro', 4821)).toBe('João#4821');
  });
  test.each([
    ['Joao#4821', { nome: 'joao', codigo: 4821 }],
    ['  João # 4821 ', { nome: 'joao', codigo: 4821 }],
    ['MARIA#1000', { nome: 'maria', codigo: 1000 }],
  ])('interpreta %p', (texto, esperado) => {
    expect(interpretarCodigo(texto)).toEqual(esperado);
  });
  test.each(['4821', 'Joao', 'Joao#48', 'Joao#48210', 'Joao Pedro#4821', '#4821', 123])(
    'recusa %p', (texto) => {
      expect(interpretarCodigo(texto)).toBeNull();
    }
  );
  test('o nome confere sem diferenciar acento e maiúsculas', () => {
    expect(nomeConfere('joao', 'João Pedro')).toBe(true);
    expect(nomeConfere('maria', 'João Pedro')).toBe(false);
  });
});

describe('montarRanking', () => {
  const pessoas = [
    { id: 1, nome: 'Carla Souza', codigo: 1111, nivel: 1, xp_total: 50 },
    { id: 7, nome: 'Ana Lima', codigo: 2222, nivel: 2, xp_total: 150 },
    { id: 3, nome: 'Bruno Reis', codigo: 3333, nivel: 1, xp_total: 50 },
  ];
  test('ordena por XP, empata na mesma posição e marca o próprio aluno', () => {
    const r = montarRanking(pessoas, 7);
    expect(r.map(p => [p.posicao, p.nome])).toEqual([[1, 'Ana'], [2, 'Bruno'], [2, 'Carla']]);
    expect(r[0]).toMatchObject({ eu: true, codigo: 'Ana#2222', nivel: 2 });
    // só o primeiro nome aparece
    expect(r.every(p => !p.nome.includes(' '))).toBe(true);
  });
  test('lista vazia', () => {
    expect(montarRanking([], 7)).toEqual([]);
  });
});

describe('rotas do ranking', () => {
  test('GET /ranking mostra o meu código e os colegas', async () => {
    banco([
      ['aparecer_no_ranking FROM usuarios', { rows: [{ id: 7, nome: 'Ana Lima', codigo: 2222, aparecer_no_ranking: true }] }],
      ['AS xp_total', { rows: [
        { id: 7, nome: 'Ana Lima', codigo: 2222, xp_total: 150 },
        { id: 3, nome: 'Bruno Reis', codigo: 3333, xp_total: 200 },
      ] }],
    ]);
    const r = await request(app).get('/ranking').set(auth);
    expect(r.status).toBe(200);
    expect(r.body).toMatchObject({ meu_codigo: 'Ana#2222', aparecer_no_ranking: true, total_colegas: 1 });
    expect(r.body.ranking.map(p => [p.posicao, p.nome, p.nivel, p.eu])).toEqual([[1, 'Bruno', 3, false], [2, 'Ana', 2, true]]);
    // nenhum dado além de nome, código, avatar, nível e XP
    expect(Object.keys(r.body.ranking[0]).sort())
      .toEqual(['avatar', 'codigo', 'eu', 'nivel', 'nome', 'posicao', 'xp_total']);
  });
  test('GET /ranking sem token: 401; usuário inexistente: 404; erro: 500', async () => {
    expect((await request(app).get('/ranking')).status).toBe(401);
    banco([]);
    expect((await request(app).get('/ranking').set(auth)).status).toBe(404);
    banco([['aparecer_no_ranking FROM usuarios', new Error('fora do ar')]]);
    expect((await request(app).get('/ranking').set(auth)).status).toBe(500);
  });

  const adicionar = codigo => request(app).post('/ranking/colegas').set(auth).send({ codigo });

  test('adiciona um colega com nome e código certos', async () => {
    banco([
      ['WHERE codigo = $1', { rows: [{ id: 3, nome: 'Bruno Reis', codigo: 3333 }] }],
      ['COUNT(*)::int AS total FROM colegas', { rows: [{ total: 0 }] }],
      ['INSERT INTO colegas', { rows: [{ colega_id: 3 }] }],
    ]);
    const r = await adicionar('bruno#3333');
    expect(r.status).toBe(201);
    expect(r.body.colega).toBe('Bruno#3333');
  });
  test('formato errado: 400', async () => {
    expect((await adicionar('3333')).status).toBe(400);
  });
  test('código inexistente e nome errado dão a mesma resposta (404)', async () => {
    banco([]);
    const r1 = await adicionar('Bruno#9999');
    banco([['WHERE codigo = $1', { rows: [{ id: 3, nome: 'Bruno Reis', codigo: 3333 }] }]]);
    const r2 = await adicionar('Carlos#3333');
    expect(r1.status).toBe(404);
    expect(r2.status).toBe(404);
    expect(r1.body.error).toBe(r2.body.error);
  });
  test('o próprio código: 400; já adicionado: 409; limite de colegas: 400', async () => {
    banco([['WHERE codigo = $1', { rows: [{ id: 7, nome: 'Ana Lima', codigo: 2222 }] }]]);
    expect((await adicionar('Ana#2222')).status).toBe(400);

    banco([
      ['WHERE codigo = $1', { rows: [{ id: 3, nome: 'Bruno Reis', codigo: 3333 }] }],
      ['COUNT(*)::int AS total FROM colegas', { rows: [{ total: 0 }] }],
    ]);
    expect((await adicionar('Bruno#3333')).status).toBe(409);

    banco([
      ['WHERE codigo = $1', { rows: [{ id: 3, nome: 'Bruno Reis', codigo: 3333 }] }],
      ['COUNT(*)::int AS total FROM colegas', { rows: [{ total: 50 }] }],
    ]);
    expect((await adicionar('Bruno#3333')).status).toBe(400);
  });
  test('erro no banco ao adicionar: 500', async () => {
    banco([['WHERE codigo = $1', new Error('fora do ar')]]);
    expect((await adicionar('Bruno#3333')).status).toBe(500);
  });

  test('remove um colega', async () => {
    banco([['DELETE FROM colegas', { rows: [{ colega_id: 3 }] }]]);
    expect((await request(app).delete('/ranking/colegas/3333').set(auth)).status).toBe(200);
    banco([]);
    expect((await request(app).delete('/ranking/colegas/3333').set(auth)).status).toBe(404);
    expect((await request(app).delete('/ranking/colegas/abc').set(auth)).status).toBe(400);
    banco([['DELETE FROM colegas', new Error('fora do ar')]]);
    expect((await request(app).delete('/ranking/colegas/3333').set(auth)).status).toBe(500);
  });

  test('liga e desliga aparecer no ranking', async () => {
    banco([]);
    const r = await request(app).put('/ranking/visibilidade').set(auth).send({ aparecer: false });
    expect(r.status).toBe(200);
    expect(r.body.aparecer_no_ranking).toBe(false);
    const params = pool.query.mock.calls.find(c => c[0].includes('SET aparecer_no_ranking'))[1];
    expect(params).toEqual([false, 7]);
    expect((await request(app).put('/ranking/visibilidade').set(auth).send({ aparecer: 'sim' })).status).toBe(400);
    banco([['SET aparecer_no_ranking', new Error('fora do ar')]]);
    expect((await request(app).put('/ranking/visibilidade').set(auth).send({ aparecer: true })).status).toBe(500);
  });
});

describe('ranking geral', () => {
  // Linhas como o banco devolve: já ordenadas, com posição (RANK), linha (ROW_NUMBER) e total
  function linhas(quantas, extra = [], total = quantas + extra.length) {
    const lista = [];
    for (let i = 1; i <= quantas; i++) {
      lista.push({ id: 100 + i, nome: `Aluno${i} Silva`, avatar: i % 12, xp_total: 1000 - i * 10, posicao: i, linha: i, total });
    }
    return [...lista, ...extra];
  }

  test('montarRankingGeral corta nos 20 primeiros e mostra a minha posição fora do top', () => {
    const eu = { id: 7, nome: 'Ana Lima', avatar: 3, xp_total: 40, posicao: 25, linha: 25, total: 25 };
    const r = montarRankingGeral(linhas(20, [eu], 25), 7, calcularNivel);
    expect(r.ranking).toHaveLength(20);
    expect(r.ranking.some(p => p.eu)).toBe(false);
    expect(r.minha_posicao).toEqual({ posicao: 25, nome: 'Ana', avatar: 3, nivel: 1, xp_total: 40, eu: true });
    expect(r.total_participantes).toBe(25);
  });
  test('montarRankingGeral sem participantes', () => {
    expect(montarRankingGeral([], 7, calcularNivel)).toEqual({ ranking: [], minha_posicao: null, total_participantes: 0 });
  });

  test('GET /ranking/geral mostra só primeiro nome, avatar, nível e XP (sem o código)', async () => {
    banco([
      ['aparecer_no_ranking FROM usuarios', { rows: [{ aparecer_no_ranking: true }] }],
      ['WITH participantes', { rows: [
        { id: 3, nome: 'Bruno Reis', avatar: 5, xp_total: 300, posicao: 1, linha: 1, total: 2 },
        { id: 7, nome: 'Ana Lima', avatar: 2, xp_total: 150, posicao: 2, linha: 2, total: 2 },
      ] }],
    ]);
    const r = await request(app).get('/ranking/geral').set(auth);
    expect(r.status).toBe(200);
    expect(r.body.ranking.map(p => [p.posicao, p.nome, p.nivel, p.eu])).toEqual([[1, 'Bruno', 4, false], [2, 'Ana', 2, true]]);
    expect(Object.keys(r.body.ranking[0]).sort()).toEqual(['avatar', 'eu', 'nivel', 'nome', 'posicao', 'xp_total']);
    expect(r.body.minha_posicao.posicao).toBe(2);
    expect(r.body.aparecer_no_ranking).toBe(true);
  });
  test('GET /ranking/geral: só alunos que aceitaram aparecer, com empate pela mesma posição', async () => {
    banco([['aparecer_no_ranking FROM usuarios', { rows: [{ aparecer_no_ranking: false }] }]]);
    const r = await request(app).get('/ranking/geral').set(auth);
    expect(r.body.minha_posicao).toBeNull();
    const [sql, params] = pool.query.mock.calls[1];
    expect(sql).toContain("u.perfil = 'aluno' AND u.aparecer_no_ranking = true");
    expect(sql).toContain('RANK() OVER');
    expect(params).toEqual([7, 20]);
  });
  test('GET /ranking/geral: sem token 401, usuário inexistente 404, erro 500', async () => {
    expect((await request(app).get('/ranking/geral')).status).toBe(401);
    banco([]);
    expect((await request(app).get('/ranking/geral').set(auth)).status).toBe(404);
    banco([['aparecer_no_ranking FROM usuarios', new Error('fora do ar')]]);
    expect((await request(app).get('/ranking/geral').set(auth)).status).toBe(500);
  });
});
