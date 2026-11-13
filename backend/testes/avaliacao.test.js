// Testes da avaliação da produção (RF07)
jest.mock('../src/servicos/ia', () => ({
  iaConfigurada: jest.fn(),
  avaliarComIA: jest.fn(),
}));
const ia = require('../src/servicos/ia');
const {
  preFiltro, avaliarPorRegras, resultadoDaNota, avaliarProducao, palavraEstranha, normalizar,
} = require('../src/servicos/avaliacao');

const aula = {
  titulo: 'O que é uma função',
  conteudo: 'Uma função relaciona cada valor de um conjunto (domínio) a exatamente um valor de outro conjunto (contradomínio). Exemplo: f(x) = 2x + 1 associa x = 3 ao valor 7.',
  palavras_chave: 'função,domínio,contradomínio,entrada,saída',
};
const BOA = 'A função é uma regra que liga cada entrada do domínio a uma única saída no contradomínio.';

beforeEach(() => jest.clearAllMocks());

describe('normalizar e palavraEstranha', () => {
  test('remove acentos e deixa minúsculo', () => {
    expect(normalizar('Função DOMÍNIO')).toBe('funcao dominio');
  });
  test('reconhece palavras digitadas ao acaso', () => {
    const vazio = new Set();
    for (const p of ['asdkjasd', 'qweqwe', 'zxczxc', 'sdfg', 'aaaa']) {
      expect(palavraEstranha(p, vazio)).toBe(true);
    }
  });
  test('não marca palavras reais do português', () => {
    const vazio = new Set();
    for (const p of ['contradominio', 'transformar', 'instrumento', 'perspectiva', 'exemplo', 'desde']) {
      expect(palavraEstranha(p, vazio)).toBe(false);
    }
  });
});

describe('preFiltro', () => {
  test('aceita uma explicação de verdade', () => {
    expect(preFiltro(BOA, aula).ok).toBe(true);
  });
  test('barra palavras-chave misturadas com letras aleatórias', () => {
    const r = preFiltro('função domínio contradomínio entrada saída asdkjasd qweqwe zxczxc fdgdfg', aula);
    expect(r).toMatchObject({ ok: false, motivo: 'sem_sentido' });
  });
  test('barra lista de palavras-chave sem frase', () => {
    const r = preFiltro('função domínio contradomínio entrada saída função domínio contradomínio', aula);
    expect(r).toMatchObject({ ok: false, motivo: 'lista_de_palavras' });
  });
  test('barra texto com poucas palavras diferentes', () => {
    expect(preFiltro('função função função função', aula).motivo).toBe('poucas_palavras');
  });
  test('barra cópia do texto da aula', () => {
    const copia = 'Uma função relaciona cada valor de um conjunto (domínio) a exatamente um valor de outro conjunto.';
    expect(preFiltro(copia, aula).motivo).toBe('copia');
  });
});

describe('avaliarPorRegras (reserva quando a IA não responde)', () => {
  test('todas as palavras-chave citadas: nota 100', () => {
    expect(avaliarPorRegras(`${BOA}`, aula.palavras_chave).nota).toBe(100);
  });
  test('parte das palavras-chave: nota proporcional e dica do que faltou', () => {
    const r = avaliarPorRegras('A função tem um domínio.', aula.palavras_chave);
    expect(r.nota).toBe(40);
    expect(r.comentario).toContain('contradomínio');
  });
  test('nenhuma palavra-chave: nota 0', () => {
    expect(avaliarPorRegras('Não sei explicar isso.', aula.palavras_chave).nota).toBe(0);
  });
  test('aula sem palavras-chave cadastradas: aceita', () => {
    expect(avaliarPorRegras('qualquer texto', null).nota).toBe(70);
  });
});

describe('resultadoDaNota', () => {
  test.each([
    [100, 'suficiente'], [70, 'suficiente'], [69, 'parcial'],
    [40, 'parcial'], [39, 'insuficiente'], [0, 'insuficiente'],
  ])('nota %i -> %s', (nota, esperado) => {
    expect(resultadoDaNota(nota)).toBe(esperado);
  });
});

describe('avaliarProducao (as 3 etapas)', () => {
  test('texto barrado no filtro nem chega na IA', async () => {
    ia.iaConfigurada.mockReturnValue(true);
    const r = await avaliarProducao('asdkj qwert zxcvb hjkl vbnm poiuy', aula);
    expect(r).toMatchObject({ nota: 0, resultado: 'insuficiente', avaliador: 'filtro' });
    expect(ia.avaliarComIA).not.toHaveBeenCalled();
  });
  test('usa a nota da IA quando ela responde', async () => {
    ia.iaConfigurada.mockReturnValue(true);
    ia.avaliarComIA.mockResolvedValue({
      nota: 55, comentario: 'Faltou a imagem.', criterios: { conceito: 30, completude: 15, clareza: 10 },
    });
    const r = await avaliarProducao(BOA, aula);
    expect(r).toMatchObject({ nota: 55, resultado: 'parcial', avaliador: 'ia' });
    expect(r.criterios.conceito).toBe(30);
  });
  test('se a IA falhar, usa as regras', async () => {
    ia.iaConfigurada.mockReturnValue(true);
    ia.avaliarComIA.mockRejectedValue(new Error('fora do ar'));
    jest.spyOn(console, 'error').mockImplementation(() => {});
    const r = await avaliarProducao(BOA, aula);
    expect(r).toMatchObject({ avaliador: 'regras', resultado: 'suficiente' });
  });
  test('sem chave da IA, usa as regras direto', async () => {
    ia.iaConfigurada.mockReturnValue(false);
    const r = await avaliarProducao(BOA, aula);
    expect(r.avaliador).toBe('regras');
    expect(ia.avaliarComIA).not.toHaveBeenCalled();
  });
});
