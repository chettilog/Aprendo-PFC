// Testes do limite de tentativas (força bruta, abuso da IA, adivinhação de códigos)
jest.mock('../src/config/banco', () => ({ query: jest.fn(async () => ({ rows: [] })), connect: jest.fn() }));
process.env.JWT_SECRET = 'segredo-de-teste';
const pool = require('../src/config/banco');
const express = require('express');
const request = require('supertest');
const { limitarTentativas, limparContadores } = require('../src/middlewares/limites');

beforeAll(() => { process.env.TESTAR_LIMITES = '1'; });
afterAll(() => { delete process.env.TESTAR_LIMITES; });
beforeEach(() => { limparContadores(); jest.clearAllMocks(); });

// App mínimo com uma rota limitada; ?ok=0 faz a rota responder com erro
function appCom(opcoes) {
  const app = express();
  app.use(express.json());
  app.post('/teste', limitarTentativas({ nome: 'teste', ...opcoes }), (req, res) => {
    res.status(req.query.ok === '0' ? 401 : 200).json({});
  });
  return app;
}

test('bloqueia com 429 depois do máximo e registra o bloqueio uma vez', async () => {
  const app = appCom({ janelaMs: 60000, maximo: 3 });
  for (let i = 0; i < 3; i++) expect((await request(app).post('/teste')).status).toBe(200);
  const r = await request(app).post('/teste');
  expect(r.status).toBe(429);
  expect(r.headers['retry-after']).toBeDefined();
  await request(app).post('/teste');
  const logs = pool.query.mock.calls.filter(c => c[0].includes('INSERT INTO logs'));
  expect(logs).toHaveLength(1);
  expect(logs[0][1][1]).toBe('limite_excedido');
});

test('contarSoFalhas: quem acerta não é punido; quem erra é bloqueado', async () => {
  const app = appCom({ janelaMs: 60000, maximo: 2, contarSoFalhas: true });
  for (let i = 0; i < 5; i++) expect((await request(app).post('/teste')).status).toBe(200);
  expect((await request(app).post('/teste?ok=0')).status).toBe(401);
  expect((await request(app).post('/teste?ok=0')).status).toBe(401);
  expect((await request(app).post('/teste?ok=0')).status).toBe(429);
  // bloqueado vale também para a tentativa certa, até a janela acabar
  expect((await request(app).post('/teste')).status).toBe(429);
});

test('a contagem é separada por chave e volta a zero quando a janela acaba', async () => {
  const app = appCom({ janelaMs: 80, maximo: 1, chave: req => req.body.email });
  expect((await request(app).post('/teste').send({ email: 'a@a.com' })).status).toBe(200);
  expect((await request(app).post('/teste').send({ email: 'a@a.com' })).status).toBe(429);
  expect((await request(app).post('/teste').send({ email: 'b@b.com' })).status).toBe(200);
  await new Promise(r => setTimeout(r, 100));
  expect((await request(app).post('/teste').send({ email: 'a@a.com' })).status).toBe(200);
});

test('sem chave (ex.: e-mail não enviado), o limite não se aplica', async () => {
  const app = appCom({ janelaMs: 60000, maximo: 1, chave: req => req.body.email });
  for (let i = 0; i < 3; i++) expect((await request(app).post('/teste').send({})).status).toBe(200);
});

test('login: a 6ª senha errada para o mesmo e-mail é bloqueada', async () => {
  const app = require('../src/app');
  const tentar = () => request(app).post('/login').send({ email: 'Alvo@Teste.com', senha: 'errada' });
  for (let i = 0; i < 5; i++) expect((await tentar()).status).toBe(401);
  const r = await tentar();
  expect(r.status).toBe(429);
  expect(r.body.error).toMatch(/nesta conta/);
  // o e-mail é comparado sem diferenciar maiúsculas
  expect((await request(app).post('/login').send({ email: 'alvo@teste.com', senha: 'x' })).status).toBe(429);
});
