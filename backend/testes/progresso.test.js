// Testes das regras do dashboard: dias seguidos e próxima aula
const { calcularDiasSeguidos, escolherProximaAula } = require('../src/servicos/progresso');

describe('calcularDiasSeguidos', () => {
  const HOJE = '2026-11-14';

  test('nunca estudou: 0', () => {
    expect(calcularDiasSeguidos([], HOJE)).toBe(0);
  });
  test('estudou só hoje: 1', () => {
    expect(calcularDiasSeguidos(['2026-11-14'], HOJE)).toBe(1);
  });
  test('hoje, ontem e anteontem: 3', () => {
    expect(calcularDiasSeguidos(['2026-11-12', '2026-11-14', '2026-11-13'], HOJE)).toBe(3);
  });
  test('ainda não estudou hoje, mas estudou ontem: a sequência continua', () => {
    expect(calcularDiasSeguidos(['2026-11-13', '2026-11-12'], HOJE)).toBe(2);
  });
  test('ficou um dia inteiro sem estudar: zera', () => {
    expect(calcularDiasSeguidos(['2026-11-12', '2026-11-11'], HOJE)).toBe(0);
  });
  test('um buraco no meio interrompe a contagem', () => {
    expect(calcularDiasSeguidos(['2026-11-14', '2026-11-13', '2026-11-10'], HOJE)).toBe(2);
  });
  test('funciona na virada do mês', () => {
    expect(calcularDiasSeguidos(['2026-10-31', '2026-11-01'], '2026-11-01')).toBe(2);
  });
});

describe('escolherProximaAula', () => {
  const aula = (id, trilha_id, concluida) => ({
    id, titulo: `Aula ${id}`, trilha_id, trilha_nome: `Trilha ${trilha_id}`, concluida,
  });

  test('aluno novo: primeira aula da primeira trilha', () => {
    const r = escolherProximaAula([aula(1, 10, false), aula(2, 10, false), aula(3, 20, false)]);
    expect(r).toEqual({ id: 1, titulo: 'Aula 1', trilha_id: 10, trilha_nome: 'Trilha 10' });
  });
  test('prefere a trilha que o aluno já começou', () => {
    const r = escolherProximaAula([aula(1, 10, false), aula(3, 20, true), aula(4, 20, false)]);
    expect(r.id).toBe(4);
  });
  test('trilha concluída é pulada', () => {
    const r = escolherProximaAula([aula(1, 10, true), aula(2, 10, true), aula(3, 20, false)]);
    expect(r.id).toBe(3);
  });
  test('tudo concluído (ou sem aulas): null', () => {
    expect(escolherProximaAula([aula(1, 10, true)])).toBeNull();
    expect(escolherProximaAula([])).toBeNull();
  });
});
