// Testes das regras de XP (RF08) e das validações de entrada
const { calcularNivel, xpDoResultado, xpAGanhar } = require('../src/servicos/xp');
const {
  validarCadastro, validarNome, validarSenha, idValido, validarProducao, validarAvatar, TOTAL_AVATARES,
} = require('../src/utils/validacoes');

describe('XP e nível', () => {
  test.each([[0, 1], [99, 1], [100, 2], [250, 3]])('%i XP -> nível %i', (xp, nivel) => {
    expect(calcularNivel(xp)).toBe(nivel);
  });
  test('valor de cada resultado', () => {
    expect(xpDoResultado('suficiente')).toBe(50);
    expect(xpDoResultado('parcial')).toBe(25);
    expect(xpDoResultado('insuficiente')).toBe(0);
  });
  test('parcial e depois suficiente: ganha só a diferença', () => {
    expect(xpAGanhar('parcial', 0)).toBe(25);
    expect(xpAGanhar('suficiente', 25)).toBe(25);
  });
  test('não ganha de novo nem perde XP', () => {
    expect(xpAGanhar('suficiente', 50)).toBe(0);
    expect(xpAGanhar('parcial', 50)).toBe(0);
    expect(xpAGanhar('insuficiente', 25)).toBe(0);
  });
});

describe('validarCadastro', () => {
  test('dados corretos', () => {
    expect(validarCadastro('Ana', 'ana@email.com', '123456')).toBeNull();
  });
  test.each([
    ['', 'a@a.com', '123456', 'obrigatórios'],
    ['A', 'a@a.com', '123456', 'nome'],
    ['Ana', 'sem-arroba', '123456', 'e-mail'],
    ['Ana', 'a@a.com', '123', 'senha'],
    ['Ana', 'a@a.com', 'x'.repeat(73), 'senha'],
  ])('rejeita (%s, %s, senha)', (nome, email, senha, trecho) => {
    expect(validarCadastro(nome, email, senha)).toMatch(new RegExp(trecho, 'i'));
  });
});

describe('validarNome e validarSenha', () => {
  test('nome', () => {
    expect(validarNome('Ana')).toBeNull();
    expect(validarNome('  Ana  ')).toBeNull();
    expect(validarNome('A')).toMatch(/entre 2 e 100/);
    expect(validarNome('   ')).toMatch(/Informe/);
    expect(validarNome(undefined)).toMatch(/Informe/);
  });
  test('senha', () => {
    expect(validarSenha('123456')).toBeNull();
    expect(validarSenha('123')).toMatch(/entre 6 e 72/);
    expect(validarSenha(123456)).toMatch(/entre 6 e 72/);
  });
});

describe('idValido e validarProducao', () => {
  test('ids', () => {
    expect(idValido('1')).toBe(true);
    expect(idValido('0')).toBe(false);
    expect(idValido('abc')).toBe(false);
    expect(idValido('1;DROP')).toBe(false);
  });
  test('produção', () => {
    expect(validarProducao('   ').erro).toMatch(/vazia/);
    expect(validarProducao(123).erro).toMatch(/vazia/);
    expect(validarProducao('curta').erro).toMatch(/pelo menos/);
    expect(validarProducao('x'.repeat(3001)).erro).toMatch(/no máximo/);
    expect(validarProducao(`  ${'a'.repeat(50)}  `).texto).toHaveLength(50);
  });
});

describe('validarAvatar', () => {
  test('aceita de 0 a 11', () => {
    expect(TOTAL_AVATARES).toBe(12);
    for (let i = 0; i < TOTAL_AVATARES; i++) expect(validarAvatar(i)).toBeNull();
  });
  test('recusa fora da faixa, decimal e texto', () => {
    for (const v of [-1, 12, 1.5, '1', null, undefined]) expect(validarAvatar(v)).toMatch(/avatar/);
  });
});
