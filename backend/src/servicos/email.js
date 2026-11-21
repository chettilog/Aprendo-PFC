// Envio de e-mail (usado na recuperação de senha).
// O Render gratuito bloqueia as portas de SMTP, então o envio é feito pela API HTTPS do Brevo.
// Variáveis: BREVO_API_KEY (chave da API) e EMAIL_REMETENTE (e-mail verificado no Brevo).
// Sem a chave, nada é enviado; com EMAIL_SIMULADO=true (só no desenvolvimento),
// o e-mail aparece no terminal do servidor, para testar sem uma conta no Brevo.

const URL_BREVO = 'https://api.brevo.com/v3/smtp/email';

function emailConfigurado() {
  return Boolean(process.env.BREVO_API_KEY && process.env.EMAIL_REMETENTE);
}

// Envia um e-mail de texto. Devolve true se foi aceito pelo Brevo, false se não.
// Nunca lança erro: quem chama não precisa tratar falha de envio.
async function enviarEmail({ para, assunto, texto }) {
  if (!emailConfigurado()) {
    if (process.env.EMAIL_SIMULADO === 'true') {
      console.log(`[e-mail simulado] Para: ${para} | Assunto: ${assunto}\n${texto}`);
      return true;
    }
    console.error('[e-mail] Envio não configurado: defina BREVO_API_KEY e EMAIL_REMETENTE');
    return false;
  }

  try {
    const resposta = await fetch(URL_BREVO, {
      method: 'POST',
      headers: {
        'api-key': process.env.BREVO_API_KEY,
        'content-type': 'application/json',
        accept: 'application/json',
      },
      body: JSON.stringify({
        sender: { name: 'Aprendo', email: process.env.EMAIL_REMETENTE },
        to: [{ email: para }],
        subject: assunto,
        textContent: texto,
      }),
      signal: AbortSignal.timeout(10000),
    });
    if (!resposta.ok) {
      console.error(`[e-mail] Brevo respondeu ${resposta.status}`);
      return false;
    }
    return true;
  } catch (err) {
    console.error('[e-mail] Falha ao enviar:', err.message);
    return false;
  }
}

module.exports = { enviarEmail, emailConfigurado, URL_BREVO };
