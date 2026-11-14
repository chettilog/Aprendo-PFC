// Testes do serviço de logs (auditoria) e das regras de LGPD sobre eles
jest.mock('../src/config/banco', () => ({ query: jest.fn() }));
const pool = require('../src/config/banco');
const {
  registrarLog, mascararEmail, removerEmailDosLogs, apagarLogsAntigos, agendarLimpezaDeLogs,
} = require('../src/servicos/logs');

beforeEach(() => {
  jest.clearAllMocks();
  jest.spyOn(console, 'error').mockImplementation(() => {});
  jest.spyOn(console, 'log').mockImplementation(() => {});
});

describe('mascararEmail', () => {
  test.each([
    ['joao.silva@email.com', 'j***@email.com'],
    ['  ana@escola.org  ', 'a***@escola.org'],
    ['a@a.com', 'a***@a.com'],
    ['sem-arroba', '***'],
    ['@email.com', '***'],
    ['joao@', '***'],
    [undefined, '***'],
    [123, '***'],
  ])('%p -> %s', (entrada, esperado) => {
    expect(mascararEmail(entrada)).toBe(esperado);
  });
});

describe('registrarLog', () => {
  test('grava o evento', async () => {
    pool.query.mockResolvedValue({ rowCount: 1 });
    await registrarLog(7, 'login', 'Login realizado', '1.2.3.4', true);
    expect(pool.query.mock.calls[0][1]).toEqual([7, 'login', 'Login realizado', '1.2.3.4', true]);
  });
  test('se o banco falhar, não derruba a aplicação', async () => {
    pool.query.mockRejectedValue(new Error('fora do ar'));
    await expect(registrarLog(7, 'login', 'x', 'ip')).resolves.toBeUndefined();
  });
});

describe('removerEmailDosLogs (exclusão de conta)', () => {
  test('troca o e-mail pela versão mascarada', async () => {
    pool.query.mockResolvedValue({ rowCount: 3 });
    expect(await removerEmailDosLogs('joao@email.com')).toBe(3);
    expect(pool.query.mock.calls[0][0]).toContain('UPDATE logs');
    expect(pool.query.mock.calls[0][1]).toEqual(['joao@email.com', 'j***@email.com']);
  });
  test('erro no banco devolve 0', async () => {
    pool.query.mockRejectedValue(new Error('fora do ar'));
    expect(await removerEmailDosLogs('joao@email.com')).toBe(0);
  });
});

describe('retenção de 6 meses', () => {
  test('apaga os logs antigos', async () => {
    pool.query.mockResolvedValue({ rowCount: 12 });
    expect(await apagarLogsAntigos()).toBe(12);
    expect(pool.query.mock.calls[0][0]).toMatch(/DELETE FROM logs.*6 months/s);
  });
  test('erro no banco devolve 0', async () => {
    pool.query.mockRejectedValue(new Error('fora do ar'));
    expect(await apagarLogsAntigos()).toBe(0);
  });
  test('a limpeza roda ao ligar o servidor e fica agendada', async () => {
    pool.query.mockResolvedValue({ rowCount: 2 });
    const relogio = agendarLimpezaDeLogs();
    await new Promise(resolve => setImmediate(resolve));
    expect(pool.query).toHaveBeenCalledTimes(1);
    expect(console.log).toHaveBeenCalledWith(expect.stringContaining('2 registro(s)'));
    clearInterval(relogio);
  });
});
