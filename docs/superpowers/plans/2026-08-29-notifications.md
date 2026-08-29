# Notificações Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trocar `AppNotification.sample` por notificações reais, geradas automaticamente no banco (trigger) quando alguém curte/comenta um post seu ou passa a te seguir.

**Architecture:** Tabela `notifications` com RLS de leitura/update só do dono (a UPDATE tem `WITH CHECK` explícito — lição do bug do DM). 3 triggers `security definer` (em `likes`, `comments`, `follows`) inserem a notificação — o client nunca insere direto. `SupabaseService` ganha 2 métodos. `NotificationsView` passa a usar dado real.

**Tech Stack:** SwiftUI, supabase-swift, Supabase Postgres + RLS + triggers.

**Spec:** `docs/superpowers/specs/2026-08-29-notifications-design.md`

## Global Constraints

- Sem "sugestões pra seguir de volta", sem push (APNs), sem notificação de menção (spec: Fora de escopo)
- `notifications` NÃO tem policy de INSERT pro client — só os 3 triggers escrevem
- A policy de UPDATE de `notifications` tem `WITH CHECK` idêntico ao `USING` — nunca repetir o bug do DM (UPDATE sem CHECK)
- Trigger nunca notifica o próprio autor da ação (curtir/comentar/seguir a si mesmo)

---

### Task 1: Migration `notifications` + 3 triggers

**Files:**
- Create: `supabase/migrations/0012_notifications.sql`

**Interfaces:**
- Produces: tabela `notifications`, 2 policies (select, update com WITH CHECK), 3 funções trigger + 3 triggers (`likes_notify`, `comments_notify`, `follows_notify`)

- [ ] **Step 1: Escrever a migration** com o SQL exato da spec (seções "Dados" e "Triggers"), ao pé da letra.
- [ ] **Step 2: NÃO tente `supabase db push`/`supabase link`** — sandbox bloqueia. Documentar no relatório, aplicação fica com o controller via Management API.
- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/0012_notifications.sql
git commit -m "feat: tabela notifications + triggers de like/comment/follow

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01M7VA3TbyjrvN1NFVSqxW8Q"
```

---

### Task 2: Modelo `DBNotification` + `SupabaseService`

**Files:**
- Create: `Spot It/Spot It/Models/DBNotification.swift`
- Modify: `Spot It/Spot It/Services/SupabaseService.swift`

**Interfaces:**
- Produces:
  - `struct DBNotification: Identifiable { let id: UUID; let actorId: UUID; let actorUsername: String; let actorAvatarUrl: String?; let kind: NotificationKind; let postId: UUID?; var isRead: Bool; let createdAt: Date }`
  - `static func fetchNotifications() async throws -> [DBNotification]`
  - `static func markNotificationRead(id: UUID) async throws`

- [ ] **Step 1: Escrever `DBNotification.swift`** (dentro de `Spot It/Spot It/Models/` — pasta sincronizada com o target, confirme com `find` depois de criar, mesma lição de sempre nesta sessão):

```swift
import Foundation

struct DBNotification: Identifiable {
    let id: UUID
    let actorId: UUID
    let actorUsername: String
    let actorAvatarUrl: String?
    let kind: NotificationKind
    let postId: UUID?
    var isRead: Bool
    let createdAt: Date
}
```

(`NotificationKind` já existe em `Models/AppNotification.swift` — reuse, não recrie)

- [ ] **Step 2: Adicionar os 2 métodos ao `SupabaseService`**:

```swift
    static func fetchNotifications() async throws -> [DBNotification] {
        try ensureSignedIn()
        guard let myId = client.auth.currentSession?.user.id else { throw SupabaseError.notSignedIn }

        struct NotificationRow: Decodable {
            let id: UUID
            let actor_id: UUID
            let kind: String
            let post_id: UUID?
            let is_read: Bool
            let created_at: Date
        }

        let rows: [NotificationRow] = try await client.from("notifications")
            .select()
            .eq("user_id", value: myId)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value

        var notifications: [DBNotification] = []
        for row in rows {
            let kind: NotificationKind
            switch row.kind {
            case "like": kind = .like
            case "comment": kind = .comment
            default: kind = .follow
            }

            struct ProfileRow: Decodable { let username: String; let avatar_url: String? }
            let profile: ProfileRow? = try? await client.from("profiles")
                .select("username, avatar_url")
                .eq("id", value: row.actor_id)
                .single()
                .execute()
                .value

            notifications.append(DBNotification(
                id: row.id, actorId: row.actor_id,
                actorUsername: profile?.username ?? "usuário", actorAvatarUrl: profile?.avatar_url,
                kind: kind, postId: row.post_id, isRead: row.is_read, createdAt: row.created_at
            ))
        }
        return notifications
    }

    static func markNotificationRead(id: UUID) async throws {
        try ensureSignedIn()
        struct MarkRead: Encodable { let is_read: Bool }
        try await client.from("notifications")
            .update(MarkRead(is_read: true))
            .eq("id", value: id)
            .execute()
    }
```

Nota: `kind` chega como `String` do Postgres (coluna `text` com `check`) — mapeamento manual pro enum Swift é mais simples que lutar com `Decodable` customizado num enum sem raw value `String` direto; se `NotificationKind` já tiver (ou puder ganhar) `: String` como raw type sem quebrar nada existente, prefira isso e simplifique o `switch`.

- [ ] **Step 3: Build** — `xcodebuild -project "Spot It/Spot It.xcodeproj" -scheme "Spotted" -destination "generic/platform=iOS Simulator" build` → `** BUILD SUCCEEDED **`.
- [ ] **Step 4: Commit**

```bash
git add "Spot It/Spot It/Models/DBNotification.swift" "Spot It/Spot It/Services/SupabaseService.swift"
git commit -m "feat: modelo DBNotification + métodos de notificações no SupabaseService

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01M7VA3TbyjrvN1NFVSqxW8Q"
```

---

### Task 3: `NotificationsView` com dado real

**Files:**
- Modify: `Spot It/Spot It/Views/NotificationsView.swift`

**Interfaces:**
- Consumes: `fetchNotifications()`, `markNotificationRead(id:)` (Task 2), `DBNotification` (Task 2)

- [ ] **Step 1: Ler o arquivo inteiro primeiro.** Trocar `@State private var notifications: [AppNotification] = []` por `@State private var notifications: [DBNotification] = []`, adicionar `.task { await load() }` + `.refreshable { await load() }`:

```swift
    private func load() async {
        notifications = (try? await SupabaseService.fetchNotifications()) ?? []
    }
```

- [ ] **Step 2: Adaptar `row(_:)`, `open(_:)`, seções.** `DBNotification` não tem `section`/`text`/`timeAgo` prontos como `AppNotification` tinha (eram hardcoded/formatados na mão nos samples) — derive:
  - Texto: monte a partir de `kind` (`"curtiu seu post"`, `"comentou no seu post"`, `"começou a seguir você"`) — mais simples que replicar texto customizado por notificação, e cobre os 3 casos reais.
  - Seção: agrupe por dia relativo a partir de `createdAt` (ex: "Hoje"/"Ontem"/"Esta Semana"/mais antigo) — pode usar `Calendar`/`DateFormatter` simples, não precisa ser sofisticado.
  - `avatarInitials`/`avatarColors`: derive de `actorUsername` reusando a mesma lógica determinística já usada em `SearchableUser` (não duplique o algoritmo — se for fácil, construa um `SearchableUser(id: notification.actorId, username: notification.actorUsername)` só pra pegar `avatarInitials`/`avatarColors` dele).
  - `open(_:)`: chama `markNotificationRead(id:)` async (fire-and-forget ou aguardado, sua escolha) e atualiza `isRead` local pra refletir na hora; navegação: `.follow` → `UserProfileView(..., userId: notification.actorId)` (real, não mais nil); `.like`/`.comment` → precisa abrir o post (`postId`) — a forma mais direta é buscar todos os posts via `fetchFeedPosts()` e achar o de `id == postId` (aceitável, mesmo padrão simples já usado em outras telas desta sessão; não crie um endpoint novo só pra isso a menos que seja trivial).
- [ ] **Step 3: Manter `suggestions: []` fixo** (fora de escopo, spec já documentou isso).
- [ ] **Step 4: Build** — `xcodebuild -project "Spot It/Spot It.xcodeproj" -scheme "Spotted" -destination "generic/platform=iOS Simulator" build` → `** BUILD SUCCEEDED **` sem erro nenhum em lugar nenhum do projeto (última task da branch).
- [ ] **Step 5: Commit**

```bash
git add "Spot It/Spot It/Views/NotificationsView.swift"
git commit -m "feat: NotificationsView usa notificações reais

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01M7VA3TbyjrvN1NFVSqxW8Q"
```
