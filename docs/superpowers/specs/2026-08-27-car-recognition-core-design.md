# Spot It — Núcleo de Reconhecimento de Carro

Data: 2026-08-27
Status: aprovado, aguardando plano de implementação

## Contexto

Spot It é um app social de "caça a carros raros/supercarros" — usuário tira foto de um carro (Lamborghini, Ferrari, Skyline, Supra, etc, nada comum tipo Corolla), o app identifica o carro e guarda numa coleção ("wallet") com valor estimado. Projeto hobby, ritmo de ~30min/dia, sem pressão de prazo.

Esta spec cobre só a primeira fatia: **captura → reconhecimento → wallet**. Feed, ranking, rede social, mapa e eventos ficam pra fatias futuras (ver estrutura de navegação já definida abaixo, mas não implementada aqui).

## Decisões já tomadas

- **Plataforma**: iOS nativo (Swift/SwiftUI). Android fica pra depois — retrabalho aceito.
- **Reconhecimento de carro**: IA multimodal pronta (Claude Vision) via prompt estruturado, sem modelo de visão computacional próprio.
- **Valor do carro**: estimado pela própria IA na mesma chamada, sem base de dados própria de preços (ver `insights/` pra evolução futura).
- **Backend**: fino, na Vercel (serverless function) — protege a chave de API da IA, não expõe no app.
- **Persistência**: Supabase (auth, Storage pra fotos, tabela `wallet_items`).
- **Fora de escopo nesta fatia**: regra de raridade decrescente por duplicata (ver insights).

## Navegação geral do app (referência, não implementada nesta fatia)

- Tab bar 1: Feed / Ranking / Rede Social + Captura + Mapa (mapa mostra fotos próprias + de quem segue)
- Tab bar 2: Reconhecimento de carro / Captura / Wallet (mapa da wallet mostra só fotos próprias)

## Arquitetura desta fatia

```
iOS App (SwiftUI)
  ├─ Tela Captura (câmera nativa, AVFoundation/UIImagePickerController)
  ├─ Tela Resultado (dados do carro reconhecido)
  └─ Tela Wallet (lista de carros + valor total somado)
       │
       ▼ HTTPS
Vercel Function (backend fino)
  └─ recebe foto → chama Claude Vision → formata JSON → devolve
       │
       ▼
Claude Vision API
  └─ retorna: modelo, ano, motor, raridade (1-10), valor estimado (USD), fato interessante
```

Persistência: Supabase (Storage para foto, tabela `wallet_items`, auth simples).

## Fluxo de dados

1. Usuário tira foto na tela de Captura.
2. App sobe a foto pro Supabase Storage → recebe URL.
3. App chama a Vercel Function passando a foto (ou URL).
4. Function chama Claude Vision com prompt estruturado pedindo JSON: `{ modelo, ano, motor, raridade, valor_estimado_usd, fato_interessante, reconhecido: bool }`.
5. Function devolve o JSON pro app.
6. App mostra o resultado na tela de Resultado.
7. Se `reconhecido = true` e usuário confirmar "salvar" → grava linha em `wallet_items` (modelo, ano, valor, raridade, fatos, foto_url, lat, lng, created_at, user_id).
8. Tela de Wallet lista os itens do usuário e soma os valores.

## Modelo de dados (Supabase)

Tabela `wallet_items`:
- `id` (uuid, pk)
- `user_id` (uuid, fk auth.users)
- `modelo` (text)
- `ano` (int, nullable)
- `motor` (text, nullable)
- `raridade` (int, 1-10)
- `valor_estimado_usd` (numeric)
- `fato_interessante` (text, nullable)
- `foto_url` (text)
- `lat`, `lng` (numeric, nullable — se permissão de localização negada)
- `created_at` (timestamptz, default now())

RLS: usuário só lê/escreve suas próprias linhas.

## Tratamento de erros

- Foto não é de um carro / carro não identificado → `reconhecido: false`, app mostra mensagem amigável ("não conseguimos identificar esse carro"), nada é salvo.
- Falha de rede/API → mensagem de erro simples, permite tentar de novo.
- Permissão de localização negada → salva sem lat/lng, não bloqueia o fluxo.

## Teste

Sem framework automatizado (fora de escopo pra hobby). Verificação manual:
- Tirar foto de um carro raro real (ou imagem impressa/tela) → conferir se modelo/ano/valor batem com a realidade.
- Tirar foto de um carro comum (ex: Corolla) → conferir comportamento (a IA pode reconhecer mas isso é aceitável nesta fase; a curadoria de "o que conta" fica pra depois).
- Salvar 2+ carros → conferir se a wallet soma o valor total corretamente.

## Regra permanente do projeto

Toda ideia legal que surgir durante o desenvolvimento e não for aplicada agora deve ser registrada em `insights/README.md`, com data, pra não se perder.
