# Política de Privacidade — Aprendo

**Versão 1.0**
**Data de publicação: [preencher no commit final]**

## 1. Quem somos

A Aprendo Tecnologia Educacional Ltda. ("Aprendo", "nós") é a controladora dos dados pessoais tratados nesta plataforma, nos termos da Lei Geral de Proteção de Dados (Lei nº 13.709/2018).

Esta Política de Privacidade descreve como coletamos, usamos, armazenamos e protegemos os dados pessoais dos usuários da plataforma Aprendo.

## 2. Dados coletados

### 2.1 Dados fornecidos no cadastro
- Nome
- Endereço de e-mail
- Senha (armazenada exclusivamente na forma de hash criptográfico, nunca em texto legível)
- Data e versão do aceite dos Termos de Uso e desta Política

### 2.2 Dados coletados durante o uso da plataforma
- Endereço IP de origem das requisições
- Data e hora de acesso
- Ações realizadas no sistema (login, cadastro, acessos ao perfil, exclusão de conta, consultas educacionais)
- Resultado das ações (sucesso ou falha)

### 2.3 Dados coletados em tentativas de acesso
Em tentativas de login com e-mail não cadastrado, o e-mail digitado é registrado nos logs de auditoria com o objetivo de identificar padrões suspeitos de acesso. Esse registro não implica em criação de conta.

### 2.4 O que não coletamos
Não coletamos: dados de localização precisa, dados biométricos, informações financeiras, dados de terceiros que não sejam o próprio titular.

## 3. Finalidades do tratamento

Cada dado é tratado com finalidade específica:

- **Nome**: identificação personalizada do usuário na plataforma
- **E-mail**: autenticação de acesso e identificação única do usuário
- **Senha (hash)**: proteção do acesso à conta
- **Data e versão do aceite dos termos**: comprovação de conformidade legal com a LGPD
- **Logs de acesso e ações**: auditoria de segurança, prevenção de fraudes e cumprimento das obrigações previstas no Marco Civil da Internet (Lei nº 12.965/2014)

## 4. Base legal para o tratamento (LGPD Art. 7º)

- **Execução de contrato (Art. 7º, V)**: para autenticação, uso do serviço e cumprimento dos Termos de Uso
- **Cumprimento de obrigação legal (Art. 7º, II)**: para os registros de acesso exigidos pelo Marco Civil da Internet
- **Legítimo interesse (Art. 7º, IX)**: para logs de segurança e prevenção de fraudes

## 5. Compartilhamento com terceiros

Os dados pessoais dos usuários **não são compartilhados** com terceiros para fins comerciais.

Utilizamos os seguintes serviços de terceiros com finalidades técnicas específicas:

### 5.1 Wikipedia (Wikimedia Foundation)
Para consultas educacionais complementares aos conteúdos das aulas. Todas as consultas são realizadas pelos servidores do Aprendo, de forma que **o endereço IP do usuário nunca é exposto** ao serviço da Wikipedia — apenas o IP do nosso servidor é enviado. Nenhum dado pessoal do usuário é transmitido; apenas o termo pesquisado.

### 5.2 Google (CanvasKit)
A interface web do Aprendo utiliza a tecnologia CanvasKit, servida pelos servidores da Google, para renderização gráfica no navegador. Esse carregamento é técnico e não implica em transmissão de dados pessoais para essa finalidade.

## 6. Segurança dos dados

Adotamos medidas técnicas e organizacionais para proteger os dados dos usuários:

- Senhas armazenadas com hash criptográfico, nunca em texto legível
- Autenticação via tokens de sessão com expiração periódica
- Middleware de autorização em todas as rotas que acessam dados protegidos
- Registro de acessos e ações relevantes para fins de auditoria
- Chaves de segurança armazenadas fora do código-fonte da aplicação
- Comunicação será realizada em HTTPS quando em ambiente de produção

## 7. Direitos do titular (LGPD Art. 18)

O titular dos dados pode, a qualquer momento:

- Confirmar a existência de tratamento de seus dados
- Solicitar acesso aos dados que temos sobre ele
- Corrigir dados incompletos ou desatualizados
- **Solicitar a exclusão de sua conta e de seus dados pessoais** (funcionalidade implementada — o usuário pode excluir a conta diretamente pela tela de perfil)
- Revogar o consentimento
- Ser informado sobre com quem compartilhamos seus dados

Para exercer esses direitos, entre em contato: **privacidade@aprendo.com.br**. Nosso prazo de resposta é de até 15 dias corridos.

## 8. Exclusão de conta e retenção de dados

### 8.1 Direito à exclusão
O usuário pode excluir sua conta a qualquer momento, através do botão "Excluir minha conta" disponível na tela de perfil. A ação exige confirmação explícita para evitar exclusões acidentais.

### 8.2 O que acontece na exclusão
- Dados pessoais (nome, e-mail, senha, aceite de termos) são apagados do banco de dados
- Registros de auditoria (logs) são **preservados de forma anonimizada** (sem vínculo com o usuário excluído), em cumprimento ao Marco Civil da Internet

### 8.3 Retenção de dados
- **Dados de conta ativa**: mantidos enquanto o usuário mantiver acesso à plataforma
- **Logs de auditoria**: retenção mínima de 6 meses, conforme exigência do Marco Civil da Internet
- **Após exclusão solicitada pelo titular**: dados pessoais apagados de imediato; logs anonimizados preservados pelo prazo legal

Está em planejamento a implementação de rotinas automatizadas para:
- Exclusão de logs após 6 meses da geração
- Anonimização de contas sem acesso há mais de 2 anos

## 9. Uso por menores de idade

O público-alvo do Aprendo é composto majoritariamente por estudantes do ensino médio, o que inclui menores de idade. Aplicamos cuidados específicos previstos no Art. 14 da LGPD:

- A idade mínima para uso da plataforma é de 12 anos
- Os dados de menores são tratados exclusivamente para fins educacionais
- Nenhum dado de menores é utilizado para publicidade comportamental
- Os responsáveis legais podem exercer os direitos do titular em nome do menor, através do e-mail **privacidade@aprendo.com.br**

Está em desenvolvimento a implementação de verificação de idade e mecanismo de autorização de responsáveis legais no cadastro, prevista para versão futura da plataforma.

## 10. Hospedagem e transferência internacional

Em ambiente de produção, a plataforma será hospedada em provedor de infraestrutura em nuvem com servidores localizados no Brasil, em conformidade com a LGPD.

## 11. Alterações nesta Política

Reservamo-nos o direito de alterar esta Política de Privacidade a qualquer momento. Quando isso ocorrer:
- A nova versão será publicada com data e número de versão atualizados
- Usuários existentes serão notificados sobre mudanças relevantes
- Poderá ser solicitado novo aceite antes do próximo acesso à plataforma

Está em planejamento a funcionalidade de solicitação automática de novo aceite quando a versão da Política for atualizada.

## 12. Encarregado de Dados (DPO) e contato

Para dúvidas, solicitações relacionadas aos seus dados pessoais ou reclamações:

**E-mail**: 

O prazo de resposta é de até 15 dias corridos.



---

*Aprendo*
*Versão 1.0*