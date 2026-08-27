import Anthropic from '@anthropic-ai/sdk';

interface Req {
  method?: string;
  body?: { imageBase64?: string };
}
interface Res {
  status(code: number): Res;
  json(body: unknown): void;
}

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const SYSTEM_PROMPT = `Você identifica carros raros/supercarros em fotos.
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
Se a foto não mostrar um carro raro/exótico claramente identificável (ex: carro popular comum como Corolla, Civic, foto não é de carro), responda { "reconhecido": false }.`;

export default async function handler(req: Req, res: Res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method not allowed' });
    return;
  }

  const { imageBase64 } = req.body ?? {};
  if (!imageBase64) {
    res.status(400).json({ error: 'imageBase64 obrigatório' });
    return;
  }

  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-5',
    max_tokens: 1024,
    system: SYSTEM_PROMPT,
    messages: [
      {
        role: 'user',
        content: [
          { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: imageBase64 } },
          { type: 'text', text: 'Identifique o carro nesta foto.' },
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
    parsed = { reconhecido: false };
  }

  res.status(200).json(parsed);
}
