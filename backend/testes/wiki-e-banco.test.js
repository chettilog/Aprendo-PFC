// Testes da consulta à Wikipedia (feita pelo servidor) e da configuração do banco
jest.mock('../src/config/banco', () => ({ query: jest.fn(), connect: jest.fn() }));
process.env.JWT_SECRET = 'segredo-de-teste';
const pool = require('../src/config/banco');
const jwt = require('jsonwebtoken');
const request = require('supertest');
const app = require('../src/app');

const auth = { Authorization: `Bearer ${jwt.sign({ id: 7 }, process.env.JWT_SECRET)}` };

beforeEach(() => {
  jest.clearAllMocks();
  jest.spyOn(console, 'error').mockImplementation(() => {});
  // a sessão confere no banco que a conta existe; o resto das consultas são os logs
  pool.query.mockImplementation(async (sql) =>
    sql.includes('senha_alterada_em') ? { rows: [{ senha_alterada_em: null }] } : { rows: [] });
});
afterEach(() => { delete global.fetch; });

const respostaWiki = (status, corpo = {}) => ({ status, ok: status >= 200 && status < 300, json: async () => corpo });
const logs = () => pool.query.mock.calls.filter(c => c[0].includes('INSERT INTO logs')).map(c => c[1]);

describe('GET /wiki/:topico', () => {
  test('sem token: 401 e a Wikipedia não é consultada', async () => {
    global.fetch = jest.fn();
    expect((await request(app).get('/wiki/Brasil')).status).toBe(401);
    expect(global.fetch).not.toHaveBeenCalled();
  });

  test('tópico encontrado: devolve só os campos usados e registra a busca', async () => {
    global.fetch = jest.fn(async () => respostaWiki(200, {
      title: 'Fotossíntese', description: 'processo biológico', extract: 'Resumo do artigo',
      content_urls: { desktop: { page: 'https://pt.wikipedia.org/wiki/Fotoss%C3%ADntese' } },
      thumbnail: { source: 'https://upload.wikimedia.org/foto.jpg' }, pageid: 123, revision: '999',
    }));
    const r = await request(app).get('/wiki/Fotossíntese').set(auth);
    expect(r.status).toBe(200);
    expect(r.body).toEqual({
      titulo: 'Fotossíntese', descricao: 'processo biológico', resumo: 'Resumo do artigo',
      link: 'https://pt.wikipedia.org/wiki/Fotoss%C3%ADntese', imagem: 'https://upload.wikimedia.org/foto.jpg',
    });
    // o tópico vai codificado na URL, e quem chama a Wikipedia é o servidor (o IP do aluno não vai junto)
    expect(global.fetch.mock.calls[0][0]).toBe('https://pt.wikipedia.org/api/rest_v1/page/summary/Fotoss%C3%ADntese');
    expect(logs()[0][1]).toBe('busca_wiki');
  });

  test('campos opcionais ausentes viram null', async () => {
    global.fetch = jest.fn(async () => respostaWiki(200, { title: 'X', extract: 'Y' }));
    const r = await request(app).get('/wiki/X').set(auth);
    expect(r.body).toEqual({ titulo: 'X', descricao: null, resumo: 'Y', link: null, imagem: null });
  });

  test('tópico inexistente: 404 e a busca sem resultado fica registrada', async () => {
    global.fetch = jest.fn(async () => respostaWiki(404));
    const r = await request(app).get('/wiki/Inexistente123').set(auth);
    expect(r.status).toBe(404);
    expect(logs()[0][1]).toBe('busca_wiki_sem_resultado');
  });

  test('tópico só com espaços: 400', async () => {
    global.fetch = jest.fn();
    expect((await request(app).get('/wiki/%20%20').set(auth)).status).toBe(400);
    expect(global.fetch).not.toHaveBeenCalled();
  });

  test('Wikipedia com erro: 502; fora do ar: 500 sem detalhes', async () => {
    global.fetch = jest.fn(async () => respostaWiki(503));
    expect((await request(app).get('/wiki/Brasil').set(auth)).status).toBe(502);
    global.fetch = jest.fn(async () => { throw new Error('getaddrinfo ENOTFOUND pt.wikipedia.org'); });
    const r = await request(app).get('/wiki/Brasil').set(auth);
    expect(r.status).toBe(500);
    expect(JSON.stringify(r.body)).not.toMatch(/ENOTFOUND/);
  });
});

describe('configuração do banco (config/banco.js)', () => {
  const ambiente = { ...process.env };
  afterEach(() => { process.env = { ...ambiente }; });

  function carregarCom(variaveis) {
    let Pool;
    jest.isolateModules(() => {
      jest.doMock('dotenv', () => ({ config: jest.fn() }));
      jest.doMock('pg', () => ({ Pool: jest.fn() }));
      process.env = { ...ambiente, ...variaveis };
      if (!('DATABASE_URL' in variaveis)) delete process.env.DATABASE_URL;
      jest.requireActual('../src/config/banco');
      Pool = require('pg').Pool;
    });
    return Pool.mock.calls[0][0];
  }

  test('na nuvem (Neon): usa DATABASE_URL com conexão segura', () => {
    const opcoes = carregarCom({ DATABASE_URL: 'postgresql://u:s@servidor/neondb' });
    expect(opcoes).toEqual({ connectionString: 'postgresql://u:s@servidor/neondb', ssl: { rejectUnauthorized: false } });
  });

  test('no computador local: usa as variáveis DB_*', () => {
    const opcoes = carregarCom({ DB_HOST: 'localhost', DB_PORT: '5432', DB_USER: 'postgres', DB_PASSWORD: 'x', DB_NAME: 'aprendo_db' });
    expect(opcoes).toEqual({ host: 'localhost', port: '5432', user: 'postgres', password: 'x', database: 'aprendo_db' });
  });
});
