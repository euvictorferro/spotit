import Anthropic from '@anthropic-ai/sdk';

interface Req {
  method?: string;
  body?: { imageBase64?: string; images?: string[] };
}
interface Res {
  status(code: number): Res;
  json(body: unknown): void;
}

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

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

export default async function handler(req: Req, res: Res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method not allowed' });
    return;
  }

  const { imageBase64, images } = req.body ?? {};
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
    max_tokens: 2048,
    system: SYSTEM_PROMPT,
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
