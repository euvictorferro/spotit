# Eventos — design

## Contexto

`EventsView`/`EventDetailView` já têm UI completa (lista, mapa do local,
"Vou"/confirmados) rodando sobre `CarEvent.sample` — hoje `events = []`
fixo, e não existe NENHUM jeito de criar um evento (mock ou real). Sem
spec/plan formal — decisões abaixo são **Ruling**.

## Objetivo

Qualquer usuário autenticado pode criar um evento (encontro de carros) com
local, data e descrição; qualquer usuário pode ver a lista e confirmar
presença ("Vou").

## Escopo

- Tabela `events` (criado por um usuário)
- Tabela `event_attendees` (RSVP — "vou")
- Criar evento a partir da aba Eventos (botão "+")
- Listar eventos futuros, mais próximos primeiro
- Confirmar/desconfirmar presença, contagem real

## Fora de escopo (Ruling)

- **Fonte externa de eventos (Eventbrite, scraping)**: o comentário
  `ponytail` do model antigo já apontava isso como decisão futura — fica
  fora, eventos são só os criados dentro do próprio app
- **Editar/cancelar evento depois de criado**: fora de escopo (mesmo
  padrão de "publicar é definitivo" já usado em posts)
- **Escolher o pino no mapa manualmente**: em vez de um seletor de mapa
  customizado, o criador digita o local como texto (ex: "Naples, FL") e o
  app resolve lat/lng via `CLGeocoder` (geocoding nativo da Apple,
  gratuito, sem API key) — suficiente pro pino aparecer no
  `EventDetailView` sem construir um picker de mapa do zero
- **Notificação de novo evento / lembrete**: fora de escopo
- **Eventos passados**: a listagem só mostra eventos futuros
  (`event_date >= now()`); sem aba de "eventos que já rolaram"

## Dados

```sql
create table events (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  location text not null,
  lat double precision,
  lng double precision,
  event_date timestamptz not null,
  description text,
  created_at timestamptz not null default now()
);

alter table events enable row level security;

create policy "events sao publicamente legiveis"
  on events for select using (true);

create policy "usuario cria evento por conta propria"
  on events for insert with check (auth.uid() = organizer_id);
```

`lat`/`lng` nullable — se o geocoding falhar (endereço não reconhecido), o
evento ainda é criado, só sem pino preciso no mapa (`EventDetailView` trata
esse caso mostrando só o texto do local, sem o `Map`).

```sql
create table event_attendees (
  event_id uuid not null references events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

alter table event_attendees enable row level security;

create policy "attendees sao publicamente legiveis"
  on event_attendees for select using (true);

create policy "usuario confirma presenca por conta propria"
  on event_attendees for insert with check (auth.uid() = user_id);

create policy "usuario cancela a propria presenca"
  on event_attendees for delete using (auth.uid() = user_id);
```

**Nenhuma das duas tabelas tem policy de UPDATE** — mesma decisão
deliberada já usada em `follows`/`likes`/`posts`/`comments` (lição do bug
de segurança do DM: nunca deixar UPDATE sem `WITH CHECK`, e aqui nem
precisa existir).

## Componentes

### `SupabaseService` (métodos novos)

- `static func createEvent(name: String, location: String, eventDate: Date, description: String?) async throws`
  — resolve `lat`/`lng` via `CLGeocoder().geocodeAddressString(location)`
  antes de inserir (best-effort, `try?` — evento é criado mesmo se o
  geocoding falhar)
- `static func fetchEvents() async throws -> [DBEvent]` — eventos futuros
  (`event_date >= now`), com contagem de confirmados e se o usuário atual
  confirmou presença (mesmo padrão N+1 já aceito nas frentes anteriores)
- `static func toggleGoing(eventId: UUID) async throws -> Bool` — mesmo
  padrão de `toggleLike`

### Modelo novo

- `DBEvent`: `id, organizerId, name, location, lat, lng, eventDate, description, attendeeCount, isGoing`

### `EventsView`

- `.task`/`.refreshable` chamando `fetchEvents()`
- Botão "+" na toolbar abre um sheet de criação simples (nome, local,
  data, descrição opcional) chamando `createEvent`
- "Vou" chama `toggleGoing` real

### `EventDetailView`

- Recebe `DBEvent` no lugar de `CarEvent`
- Mapa só aparece se `lat`/`lng` não forem nil

## Erros e edge cases

- Confirmar presença duas vezes rápido (double-tap) → mesmo tratamento de
  duplicata já usado em `follow()`/`toggleLike`
- Geocoding falha (endereço inválido/sem internet no momento da criação)
  → evento criado sem coordenadas, mapa omitido no detalhe

## Testando

Self-check manual: criar evento, ver na lista de outra conta, confirmar
presença, contagem sobe, desconfirmar, contagem volta.
