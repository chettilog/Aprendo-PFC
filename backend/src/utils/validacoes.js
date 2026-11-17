// Validações de entrada usadas pelas rotas

// Limites do texto da produção do aluno (RF06)
const PRODUCAO_MIN = 40;
const PRODUCAO_MAX = 3000;
// Quantidade de avatares prontos do app (ícones numerados de 0 a 11)
const TOTAL_AVATARES = 12;

// Regras de cada campo; cada função retorna a mensagem de erro ou null se estiver tudo certo
function validarNome(nome) {
  if (typeof nome !== 'string' || nome.trim().length === 0) return 'Informe o nome';
  if (nome.trim().length < 2 || nome.trim().length > 100) {
    return 'O nome deve ter entre 2 e 100 caracteres';
  }
  return null;
}

function validarSenha(senha) {
  if (typeof senha !== 'string' || senha.length < 6 || senha.length > 72) {
    return 'A senha deve ter entre 6 e 72 caracteres';
  }
  return null;
}

// Valida os campos do cadastro; retorna a mensagem de erro ou null se estiver tudo certo
function validarCadastro(nome, email, senha) {
  if (!nome || !email || typeof senha !== 'string' || senha.length === 0) {
    return 'Nome, e-mail e senha são obrigatórios';
  }
  const erroNome = validarNome(nome);
  if (erroNome) return erroNome;
  if (email.length > 100 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return 'Informe um e-mail válido';
  }
  return validarSenha(senha);
}

// Valida se o parâmetro da URL é um número inteiro positivo
function idValido(valor) {
  return /^[1-9][0-9]{0,8}$/.test(valor);
}

// Valida o texto da produção; retorna { erro } ou { texto } já sem espaços nas pontas
function validarProducao(conteudo) {
  if (typeof conteudo !== 'string' || conteudo.trim().length === 0) {
    return { erro: 'A produção não pode ficar vazia' };
  }
  const texto = conteudo.trim();
  if (texto.length < PRODUCAO_MIN) {
    return { erro: `A produção deve ter pelo menos ${PRODUCAO_MIN} caracteres` };
  }
  if (texto.length > PRODUCAO_MAX) {
    return { erro: `A produção deve ter no máximo ${PRODUCAO_MAX} caracteres` };
  }
  return { texto };
}

// O avatar precisa ser um número inteiro entre 0 e TOTAL_AVATARES - 1
function validarAvatar(avatar) {
  if (!Number.isInteger(avatar) || avatar < 0 || avatar >= TOTAL_AVATARES) {
    return `Escolha um avatar de 0 a ${TOTAL_AVATARES - 1}`;
  }
  return null;
}

module.exports = {
  PRODUCAO_MIN, PRODUCAO_MAX, TOTAL_AVATARES,
  validarNome, validarSenha, validarCadastro, idValido, validarProducao, validarAvatar,
};
