// Testes da recuperação de senha (código por e-mail) e do serviço de e-mail
jest.mock('../src/config/banco', () => ({ query: jest.fn(), connect: jest.fn() }));
process.env.JWT_SECRET = 'segredo-de-teste';
const pool = require('../src/config/banco');
const bcrypt = require('bcrypt');
const request = require('supertest');
const app = require('../src/app');
const { gerarCodigo, textoDoEmail } = require('../src/rotas/recuperacao');
const { enviarEmail, emailConfigurado, URL_BREVO } = require('../src/servicos/email');

// Simula o banco: a primeira regra cujo trecho aparecer no SQL responde
function banco(regras) {
  pool.query.mockImplementation(async (sql) => {
    for (const [trecho, resposta] of regras) {
      if (sql.includes(trecho)) {
        if (resposta instanceof Error) throw resposta;
        return resposta;
      }
    }
    return { rows: [] };
  });
}
const chamadas = (trecho) => pool.query.mock.calls.filter(c => c[0].includes(trecho));

const ambiente = { ...process.env };
beforeEach(() => {
  jest.clearAllMocks();
  jest.spyOn(console, 'log').mockImplementation(() => {});
  jest.spyOn(console, 'error').mockImplementation(() => {});
  process.env = { ...ambiente };
  delete process.env.BREVO_API_KEY;
  delete process.env.EMAIL_REMETENTE;
  process.env.EMAIL_SIMULADO = 'true';
});
afterAll(() => { process.env = ambiente; });

describe('gerarCodigo e texto do e-mail', () => {
  test('código sempre com 6 dígitos', () => {
    for (let i = 0; i < 200; i++) expect(gerarCodigo()).toMatch(/^\d{6}$/);
  });
  test('e-mail traz o primeiro nome, o código e a validade', () => {
    const t = textoDoEmail('Maria Souza', '012345');
    expect(t).toContain('Olá, Maria!');
    expect(t).toContain('012345');
    expect(t).toContain('15 minutos');
  });
});

describe('POST /senha/esqueci', () => {
  test('sem e-mail: 400', async () => {
    expect((await request(app).post('/senha/esqueci').send({})).status).toBe(400);
  });
  test('e-mail sem conta: mesma resposta de quem tem conta, e nada é gravado', async () => {
    banco([]);
    const semConta = await request(app).post('/senha/esqueci').send({ email: 'ninguem@x.com' });
    banco([['FROM usuarios WHERE lower(email)', { rows: [{ id: 7, nome: 'Ana Lima', email: 'ana@x.com' }] }]]);
    const comConta = await request(app).post('/senha/esqueci').send({ email: 'ana@x.com' });
    expect(semConta.status).toBe(200);
    expect(semConta.body).toEqual(comConta.body);
  });
  test('com conta: cancela códigos antigos, grava só o hash e envia o código por e-mail', async () => {
    banco([['FROM usuarios WHERE lower(email)', { rows: [{ id: 7, nome: 'Ana Lima', email: 'ana@x.com' }] }]]);
    const r = await request(app).post('/senha/esqueci').send({ email: '  ANA@x.com ' });
    expect(r.status).toBe(200);
    expect(chamadas('FROM usuarios WHERE lower(email)')[0][1]).toEqual(['ANA@x.com']);
    expect(chamadas('SET usado_em = now() WHERE usuario_id')).toHaveLength(1);
    const [, params] = chamadas('INSERT INTO recuperacoes_senha')[0];
    expect(params[0]).toBe(7);
    expect(params[2]).toBe(15);
    // o e-mail simulado traz o código, e o banco guarda só o hash dele
    await new Promise(r => setImmediate(r));
    const email = console.log.mock.calls.map(c => c[0]).find(t => t.includes('[e-mail simulado]'));
    const codigo = email.match(/é: (\d{6})/)[1];
    expect(params[1]).not.toContain(codigo);
    expect(await bcrypt.compare(codigo, params[1])).toBe(true);
  });
  test('falha no envio do e-mail fica registrada nos logs', async () => {
    delete process.env.EMAIL_SIMULADO;
    banco([['FROM usuarios WHERE lower(email)', { rows: [{ id: 7, nome: 'Ana', email: 'ana@x.com' }] }]]);
    expect((await request(app).post('/senha/esqueci').send({ email: 'ana@x.com' })).status).toBe(200);
    await new Promise(r => setTimeout(r, 20));
    expect(chamadas('INSERT INTO logs').some(c => c[1][1] === 'recuperacao_email_falha')).toBe(true);
  });
  test('erro no banco: 500 sem detalhes', async () => {
    banco([['FROM usuarios WHERE lower(email)', new Error('relation usuarios')]]);
    const r = await request(app).post('/senha/esqueci').send({ email: 'ana@x.com' });
    expect(r.status).toBe(500);
    expect(JSON.stringify(r.body)).not.toMatch(/relation/);
  });
});

describe('POST /senha/redefinir', () => {
  const pedido = async (extra = {}) => ({
    id: 3, usuario_id: 7, codigo_hash: await bcrypt.hash('123456', 4), tentativas: 0, ...extra,
  });
  const enviar = (corpo) => request(app).post('/senha/redefinir').send(corpo);

  test('dados incompletos ou senha fraca: 400 sem consultar o código', async () => {
    banco([]);
    expect((await enviar({ email: 'ana@x.com', codigo: '12345', novaSenha: 'Nova1234' })).status).toBe(400);
    expect((await enviar({ email: 'ana@x.com', codigo: 'abcdef', novaSenha: 'Nova1234' })).status).toBe(400);
    expect((await enviar({ codigo: '123456', novaSenha: 'Nova1234' })).status).toBe(400);
    expect((await enviar({ email: 'ana@x.com', codigo: '123456', novaSenha: '123' })).status).toBe(400);
    expect(chamadas('FROM recuperacoes_senha')).toHaveLength(0);
  });
  test('sem pedido válido (expirado, usado ou inexistente): 400', async () => {
    banco([]);
    const r = await enviar({ email: 'ana@x.com', codigo: '123456', novaSenha: 'Nova1234' });
    expect(r.status).toBe(400);
    expect(r.body.error).toMatch(/expirado/);
    const [sql] = chamadas('FROM recuperacoes_senha r')[0];
    expect(sql).toContain('r.usado_em IS NULL');
    expect(sql).toContain('r.expira_em > now()');
  });
  test('pedido que já gastou as 5 tentativas: 400 mesmo com o código certo', async () => {
    banco([['FROM recuperacoes_senha r', { rows: [await pedido({ tentativas: 5 })] }]]);
    expect((await enviar({ email: 'ana@x.com', codigo: '123456', novaSenha: 'Nova1234' })).status).toBe(400);
    expect(chamadas('UPDATE usuarios SET senha')).toHaveLength(0);
  });
  test('código errado: conta a tentativa e não troca a senha', async () => {
    banco([['FROM recuperacoes_senha r', { rows: [await pedido()] }]]);
    const r = await enviar({ email: 'ana@x.com', codigo: '654321', novaSenha: 'Nova1234' });
    expect(r.status).toBe(400);
    expect(r.body.error).toMatch(/incorreto/);
    expect(chamadas('SET tentativas = tentativas + 1')[0][1]).toEqual([3, 5]);
    expect(chamadas('UPDATE usuarios SET senha')).toHaveLength(0);
  });
  test('código certo: troca a senha, encerra as sessões e invalida o código', async () => {
    banco([['FROM recuperacoes_senha r', { rows: [await pedido()] }]]);
    const r = await enviar({ email: 'ana@x.com', codigo: '123456', novaSenha: 'Nova1234' });
    expect(r.status).toBe(200);
    const [, params] = chamadas('UPDATE usuarios SET senha')[0];
    expect(await bcrypt.compare('Nova1234', params[0])).toBe(true);
    expect(params[1]).toBeInstanceOf(Date);
    expect(params[2]).toBe(7);
    expect(chamadas('SET usado_em = now() WHERE usuario_id')[0][1]).toEqual([7]);
    expect(chamadas('INSERT INTO logs').some(c => c[1][1] === 'recuperacao_senha')).toBe(true);
  });
  test('erro no banco: 500', async () => {
    banco([['FROM recuperacoes_senha r', new Error('fora do ar')]]);
    expect((await enviar({ email: 'ana@x.com', codigo: '123456', novaSenha: 'Nova1234' })).status).toBe(500);
  });
});

describe('serviço de e-mail (Brevo)', () => {
  afterEach(() => { delete global.fetch; });

  test('sem configuração e sem simulação: não envia e avisa no log do servidor', async () => {
    delete process.env.EMAIL_SIMULADO;
    expect(emailConfigurado()).toBe(false);
    expect(await enviarEmail({ para: 'a@a.com', assunto: 'x', texto: 'y' })).toBe(false);
    expect(console.error).toHaveBeenCalled();
  });
  test('configurado: chama a API do Brevo com a chave no cabeçalho', async () => {
    process.env.BREVO_API_KEY = 'chave-teste';
    process.env.EMAIL_REMETENTE = 'aprendo@x.com';
    global.fetch = jest.fn(async () => ({ ok: true, status: 201 }));
    expect(await enviarEmail({ para: 'ana@x.com', assunto: 'Assunto', texto: 'Texto' })).toBe(true);
    const [url, opcoes] = global.fetch.mock.calls[0];
    expect(url).toBe(URL_BREVO);
    expect(opcoes.headers['api-key']).toBe('chave-teste');
    const corpo = JSON.parse(opcoes.body);
    expect(corpo.sender.email).toBe('aprendo@x.com');
    expect(corpo.to).toEqual([{ email: 'ana@x.com' }]);
    expect(corpo.textContent).toBe('Texto');
  });
  test('Brevo recusa ou fica fora do ar: devolve false sem lançar erro', async () => {
    process.env.BREVO_API_KEY = 'chave-teste';
    process.env.EMAIL_REMETENTE = 'aprendo@x.com';
    global.fetch = jest.fn(async () => ({ ok: false, status: 401 }));
    expect(await enviarEmail({ para: 'a@a.com', assunto: 'x', texto: 'y' })).toBe(false);
    global.fetch = jest.fn(async () => { throw new Error('timeout'); });
    expect(await enviarEmail({ para: 'a@a.com', assunto: 'x', texto: 'y' })).toBe(false);
  });
});
