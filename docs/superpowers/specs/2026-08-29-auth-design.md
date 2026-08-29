# Auth — design

## Contexto

Hoje o app não tem autenticação real. `SupabaseService.ensureSignedIn()` chama
`client.auth.signInAnonymously()` a cada sessão — sem persistência entre
devices/reinstalls. `ProfileView` usa dados hardcoded em `@State`
(`displayName`, `username`, `bio`), sem backend. Feed/DM/Busca/Eventos/Mapa
tiveram seus mockups removidos e esperam dados reais de usuário (commit
`4faf6a1`). A Wallet foi zerada de propósito (commit `3ac0f63`), então não há
dado real de usuário anônimo a preservar.

## Objetivo

Dar ao app uma identidade de usuário real e persistente: cadastro/login,
sessão que sobrevive a restart, e um perfil (`profiles`) que o resto do app
(Wallet, Feed, DM, Busca) pode referenciar por `user_id`.

## Escopo

- Email/senha (Supabase Auth nativo)
- Sign in with Apple (obrigatório pro app store por ter login social)
- Onboarding de username após primeiro login
- Perfil editável (`profiles` table) consumido pelo `ProfileView` real

## Fora de escopo

- Recuperação de senha por email (fluxo padrão do Supabase cobre por ora;
  UI dedicada fica pra depois)
- Login Google/Facebook
- Deep link customizado de confirmação de email — usa o padrão do Supabase
- Migração de dados de usuários anônimos existentes (não há dado real a
  preservar)

## Dados

### Tabela `profiles` (migration nova)

```sql
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text,
  bio text,
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;

-- leitura pública: perfis aparecem em Busca/Feed/DM pra qualquer usuário
create policy "profiles are publicly readable"
  on profiles for select using (true);

-- só o dono edita/cria a própria linha
create policy "users manage own profile"
  on profiles for insert with check (auth.uid() = id);

create policy "users update own profile"
  on profiles for update using (auth.uid() = id);
```

`username` único e obrigatório (constraint garante — a UI trata erro de
colisão mostrando "username indisponível").

## Componentes

### `AuthService` (novo, `Spot It/Spot It/Services/AuthService.swift`)

Observable object central de identidade:

- `signUp(email: String, password: String) async throws`
- `signIn(email: String, password: String) async throws`
- `signInWithApple() async throws` — usa `ASAuthorizationController` pra
  pegar o id token da Apple e troca por sessão via
  `client.auth.signInWithIdToken(credentials:)`
- `signOut() async throws`
- `@Published var session: Session?` — espelha `client.auth.currentSession`,
  atualizado ao observar `client.auth.authStateChanges`
- `@Published var profile: Profile?` — carregado de `profiles` quando
  `session` muda; `nil` quando não há sessão ou o perfil ainda não existe
  (usuário novo, precisa de onboarding)
- `func createProfile(username: String, displayName: String?, avatarData: Data?) async throws`
  — usado pelo onboarding; faz upload de avatar (se houver) pro bucket
  existente e insere a linha em `profiles`

`Profile` é uma struct `Decodable` simples mapeando as colunas acima.

### `ContentView` — gate de 3 estados

```
switch:
  authService.session == nil            → AuthView
  authService.session != nil && profile == nil → OnboardingView
  else                                   → TabView (atual)
```

`AuthService` é instanciado como `@StateObject` no `Spot_ItApp` e injetado via
`.environmentObject`.

### `AuthView` (novo)

Toggle simples entre "Entrar" e "Criar conta", campos email/senha, botão
"Continuar com Apple" (usa `SignInWithAppleButton` do SDK nativo). Erros de
auth (senha errada, email já em uso) mostrados inline.

### `OnboardingView` (novo)

Campo de username (validação: 3-20 chars, sem espaço), foto opcional
(reusa o `PhotosPicker` já usado em `ProfileView`). Ao confirmar, chama
`AuthService.createProfile`.

### `SupabaseService.ensureSignedIn()`

Perde o fallback anônimo — vira:

```swift
static func ensureSignedIn() throws {
    guard client.auth.currentSession != nil else {
        throw SupabaseError.notSignedIn
    }
}
```

(deixa de ser `async` já que não dispara mais rede; call sites ajustados)

### `ProfileView`

Troca os `@State` hardcoded por `@EnvironmentObject var authService`,
lendo `authService.profile`. "Edit Profile" grava via um novo
`AuthService.updateProfile(...)` (update na própria linha).

## Erros e edge cases

- Username já existente no onboarding → mensagem inline, não deixa
  avançar (erro de constraint único vira mensagem amigável)
- Apple Sign In cancelado pelo usuário → volta pra `AuthView` sem erro
- Sessão expirada em background → `authStateChanges` já reflete isso,
  `ContentView` reage e volta pro `AuthView`
- `wallet_items` e demais tabelas que hoje dependem de `user_id` de sessão
  anônima continuam funcionando sem mudança de schema — só passam a
  receber `user_id` de sessão real

## Testando

Não há testes automatizados de UI hoje no projeto — segue o padrão. Como
checagem manual mínima (self-check): criar conta nova → completar
onboarding com username → forçar quit do app → reabrir → confirmar que
cai direto no `TabView` com o mesmo perfil (sessão persistida). Repetir
o mesmo fluxo com Sign in with Apple.
