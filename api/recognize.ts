import Anthropic from '@anthropic-ai/sdk';

interface Req {
  method?: string;
  headers?: Record<string, string | string[] | undefined>;
  body?: { imageBase64?: string; images?: string[]; quick?: boolean };
}
interface Res {
  status(code: number): Res;
  json(body: unknown): void;
}

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

// Sem isso o endpoint era um sink público e pago: qualquer um na internet
// podia POSTar aqui e queimar nosso orçamento de Anthropic, sem app nem
// conta nenhuma — falhava "aberto". Aqui ele falha fechado: sem um token
// de usuário Supabase válido, 401 antes de gastar um único token de IA.
// Não precisa de segredo extra no servidor — a mesma anon key pública do
// app basta pra pedir ao Supabase Auth pra validar o token do usuário.
const SUPABASE_URL = 'https://mevdvmjtkkcerkakzkch.supabase.co';
const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ldmR2bWp0a2tjZXJrYWt6a2NoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc4NDMwOTMsImV4cCI6MjEwMzQxOTA5M30.Cm36acvnAKTfjYjFMXX8ifyY849-goGnYrO9vQyEZP0';

async function authenticatedUserId(req: Req): Promise<string | null> {
  const authHeader = req.headers?.authorization;
  const token = typeof authHeader === 'string' && authHeader.startsWith('Bearer ')
    ? authHeader.slice(7)
    : null;
  if (!token) return null;

  const resp = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { Authorization: `Bearer ${token}`, apikey: SUPABASE_ANON_KEY },
  });
  if (!resp.ok) return null;
  const user = (await resp.json()) as { id?: string };
  return user.id ?? null;
}

const SYSTEM_PROMPT = `Você identifica carros raros/supercarros em fotos e escreve um perfil
completo do carro, no estilo de apps de catalogação (ex: apps que identificam moedas
e mostram análise de raridade, mercado, specs físicas e variantes famosas).
Responda SOMENTE com um JSON válido, sem markdown, no formato:
{
  "reconhecido": boolean,
  "modelo": string,
  "ano": number,
  "motor": string,
  "raridade": number (1 a 10, quão raro/exótico é o carro),
  "valor_estimado_usd": number,
  "fato_interessante": string,

  "potencia_cv": number ou null,
  "aceleracao_0_100": number ou null (segundos, ex: 2.9),
  "velocidade_maxima_kmh": number ou null,
  "peso_kg": number ou null,
  "pais_origem": string ou null,
  "producao_total": number ou null (unidades fabricadas; null se produção em massa/desconhecida),

  "analise_raridade": string ou null (2-3 frases explicando POR QUE esse carro tem essa raridade — produção limitada, exclusividade, etc, no estilo "Supply Analysis"),
  "analise_mercado": string ou null (2-3 frases sobre valorização, demanda de colecionadores/entusiastas, tendência de preço, no estilo "Market Demand and Value"),

  "design_exterior": string ou null (2-3 frases sobre o design externo, linguagem visual, elementos marcantes),
  "design_interior": string ou null (2-3 frases sobre o interior/cabine, materiais, tecnologia),

  "variante_especial": {
    "nome": string (ex: "Edição Aniversário" ou uma versão mais rara/cara do mesmo modelo),
    "ano": number,
    "valor_estimado_usd": number,
    "descricao": string (1-2 frases)
  } ou null (só preenche se existir uma variante/edição especial real e notável desse modelo),

  "serie": string ou null (a linha/submarca de performance dentro do modelo, ex: "AMG", "GT3", "STO", "M", "Nismo" — só a parte do nome que representa essa linha),
  "variante_mais_rara": {
    "nome": string (uma versão AINDA mais rara/extrema desse carro — ex: preparação de um tuner famoso tipo Mansory, Brabus, Liberty Walk, ou uma edição limitadíssima),
    "ano": number,
    "valor_estimado_usd": number,
    "descricao": string (1-2 frases explicando o que torna essa versão mais extrema)
  } ou null,

  "entre_eixos_mm": number ou null,
  "comprimento_mm": number ou null,
  "composicao": string ou null (materiais estruturais notáveis, ex: "Monocoque em fibra de carbono, painéis em alumínio"),
  "designer": string ou null (nome do designer ou estúdio de design responsável, se conhecido),

  "material_bancos": string ou null,
  "material_volante": string ou null,
  "interior_destaque": string ou null (1-2 frases sobre tecnologia/detalhe marcante do interior)
}
Faça sua melhor estimativa mesmo se não tiver 100% de certeza da variante exata (ex: confundir STO com EVO) — responda com o modelo mais provável, não recuse por incerteza de detalhe. Se receber mais de uma foto, são ângulos diferentes do mesmo carro — combine as pistas de todas (crachás, silhueta, faróis) antes de decidir. Só responda { "reconhecido": false } se a foto claramente não for de um carro raro/exótico (ex: carro popular comum como Corolla, Civic, ou a foto não é de um carro).
Todos os campos numéricos/texto além dos 7 primeiros são opcionais — use null quando não tiver certeza, nunca invente números.`;

// Chamada "quick" — só os 7 campos essenciais, sem o perfil completo (que
// é uma resposta bem mais longa e domina o tempo do scan). O app pede essa
// primeiro pra mostrar resultado rápido, e completa o resto depois com uma
// 2ª chamada em background (quick: false) usando as mesmas fotos.
const QUICK_SYSTEM_PROMPT = `Você identifica carros raros/supercarros em fotos.
Responda SOMENTE com um JSON válido, sem markdown, no formato:
{
  "reconhecido": boolean,
  "modelo": string,
  "ano": number,
  "motor": string,
  "raridade": number (1 a 10, quão raro/exótico é o carro),
  "valor_estimado_usd": number,
  "fato_interessante": string
}
Faça sua melhor estimativa mesmo se não tiver 100% de certeza da variante exata — responda com o modelo mais provável, não recuse por incerteza de detalhe. Se receber mais de uma foto, são ângulos diferentes do mesmo carro — combine as pistas de todas antes de decidir. Só responda { "reconhecido": false } se a foto claramente não for de um carro raro/exótico (ex: carro popular comum como Corolla, Civic, ou a foto não é de um carro).`;

export default async function handler(req: Req, res: Res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method not allowed' });
    return;
  }

  if (!(await authenticatedUserId(req))) {
    res.status(401).json({ error: 'unauthorized' });
    return;
  }

  const { imageBase64, images, quick } = req.body ?? {};
  const allImages = images?.length ? images : imageBase64 ? [imageBase64] : [];
  if (!allImages.length) {
    res.status(400).json({ error: 'imageBase64 ou images obrigatório' });
    return;
  }

  const promptText = allImages.length > 1
    ? `Identifique o carro — estas ${allImages.length} fotos são ângulos diferentes do mesmo veículo, use todas juntas.`
    : 'Identifique o carro nesta foto.';

  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-5',
    // 1024 cortava a resposta no meio em carros com bastante texto pros
    // campos extras (design/raridade/mercado/variantes), quebrando o JSON e
    // fazendo cair no fallback de "não reconhecido" mesmo em carros comuns.
    // No modo quick só os 7 campos essenciais, então 400 sobra de sobra.
    max_tokens: quick ? 400 : 2048,
    system: quick ? QUICK_SYSTEM_PROMPT : SYSTEM_PROMPT,
    messages: [
      {
        role: 'user',
        content: [
          ...allImages.map((data) => ({
            type: 'image' as const,
            source: { type: 'base64' as const, media_type: 'image/jpeg' as const, data },
          })),
          { type: 'text', text: promptText },
        ],
      },
    ],
  });

  const textBlock = message.content.find((b) => b.type === 'text');
  const raw = textBlock && 'text' in textBlock ? textBlock.text : '{"reconhecido": false}';
  // Claude às vezes envolve o JSON em ```json ... ``` mesmo quando instruído a não fazer isso.
  const cleaned = raw.trim().replace(/^```(?:json)?\s*/i, '').replace(/```\s*$/i, '');
  let parsed;
  try {
    parsed = JSON.parse(cleaned);
  } catch {
    // Loga o motivo real (visível nos logs da Vercel) em vez de mascarar
    // tudo como "carro não reconhecido" — se stop_reason for "max_tokens",
    // a resposta foi cortada no meio do JSON, não é falta de reconhecimento.
    console.error('Falha ao parsear resposta do Claude', { stopReason: message.stop_reason, raw: cleaned.slice(-200) });
    parsed = { reconhecido: false };
  }

  res.status(200).json(parsed);
}
