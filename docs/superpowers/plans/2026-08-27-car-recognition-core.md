# Núcleo de Reconhecimento de Carro — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App iOS que tira foto de um carro, reconhece via IA, mostra dados e salva numa wallet com valor total somado.

**Architecture:** App iOS (SwiftUI) chama uma Vercel Function (backend fino) que chama Claude Vision e devolve dados estruturados do carro. Persistência em Supabase (Storage + Postgres).

**Tech Stack:** Swift/SwiftUI (iOS nativo), Vercel Functions (Node/TypeScript), Supabase (Postgres + Storage + Auth), Claude API (modelo com visão).

**Spec:** `docs/superpowers/specs/2026-08-27-car-recognition-core-design.md`

## Global Constraints

- Fora de escopo nesta fatia: feed, ranking, rede social, mapa, eventos, chat, regra de raridade decrescente por duplicata.
- Sem base de dados própria de preços — valor vem da estimativa da IA.
- Sem testes automatizados — verificação manual no simulador/dispositivo (ver spec, seção Teste).
- Toda chave secreta (Supabase service role, Anthropic API key) só existe como env var — nunca em código commitado.
- Toda ideia fora de escopo que surgir durante a implementação vai para `insights/README.md`.

---

## File Structure

```
Spot It/
  Spot It/Spot It/                    (projeto Xcode já criado)
    Spot_ItApp.swift
    ContentView.swift                 → vira a TabView raiz (Captura/Wallet)
    Models/CarInfo.swift              → struct CarInfo (decodifica resposta do backend)
    Services/SupabaseService.swift    → upload de foto, CRUD wallet_items
    Services/RecognizeService.swift   → chama a Vercel Function
    Views/CaptureView.swift           → câmera + botão de captura
    Views/ResultView.swift            → mostra CarInfo, botão salvar
    Views/WalletView.swift            → lista + soma total
  api/
    recognize.ts                      → Vercel Function
  supabase/
    migrations/0001_wallet_items.sql  → tabela wallet_items + RLS
  vercel.json                         → aponta api/ como functions
  package.json                        → deps da function (@anthropic-ai/sdk)
```

---

### Task 1: Tabela `wallet_items` no Supabase

**Files:**
- Create: `supabase/migrations/0001_wallet_items.sql`

**Interfaces:**
- Produces: tabela `wallet_items` (id, user_id, modelo, ano, motor, raridade, valor_estimado_usd, fato_interessante, foto_url, lat, lng, created_at) com RLS por `user_id`.

- [ ] **Step 1: Escrever a migration**

```sql
create table wallet_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  modelo text not null,
  ano int,
  motor text,
  raridade int not null check (raridade between 1 and 10),
  valor_estimado_usd numeric not null,
  fato_interessante text,
  foto_url text not null,
  lat numeric,
  lng numeric,
  created_at timestamptz not null default now()
);

alter table wallet_items enable row level security;

create policy "usuarios leem seus proprios itens"
  on wallet_items for select
  using (auth.uid() = user_id);

create policy "usuarios inserem seus proprios itens"
  on wallet_items for insert
  with check (auth.uid() = user_id);
```

- [ ] **Step 2: Rodar a migration no Supabase**

No dashboard do Supabase (o projeto já criado) → SQL Editor → cola o conteúdo do arquivo → Run.

- [ ] **Step 3: Verificar manualmente**

No SQL Editor, rodar `select * from wallet_items;` — deve retornar tabela vazia sem erro.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/0001_wallet_items.sql
git commit -m "feat: cria tabela wallet_items com RLS"
```

---

### Task 2: Backend fino — Vercel Function de reconhecimento

**Files:**
- Create: `package.json`
- Create: `api/recognize.ts`
- Create: `vercel.json`

**Interfaces:**
- Consumes: env vars `ANTHROPIC_API_KEY` (configurada na Vercel, não no código)
- Produces: endpoint `POST /api/recognize` — recebe `{ imageBase64: string }`, devolve JSON:
  ```ts
  {
    reconhecido: boolean,
    modelo?: string,
    ano?: number,
    motor?: string,
    raridade?: number,       // 1-10
    valor_estimado_usd?: number,
    fato_interessante?: string
  }
  ```

- [ ] **Step 1: Criar `package.json`**

```json
{
  "name": "spotit-backend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@anthropic-ai/sdk": "^0.32.0"
  }
}
```

- [ ] **Step 2: Instalar dependências**

Run: `cd "/Users/victorferro/Projetos/Spot It" && npm install`
Expected: `node_modules/` criado, sem erros.

- [ ] **Step 3: Criar a function**

```typescript
// api/recognize.ts
import Anthropic from '@anthropic-ai/sdk';

export const config = { runtime: 'nodejs' };

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

export default async function handler(req: Request): Promise<Response> {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method not allowed' }), { status: 405 });
  }

  const { imageBase64 } = await req.json();
  if (!imageBase64) {
    return new Response(JSON.stringify({ error: 'imageBase64 obrigatório' }), { status: 400 });
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

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    parsed = { reconhecido: false };
  }

  return new Response(JSON.stringify(parsed), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });
}
```

- [ ] **Step 4: Criar `vercel.json`**

```json
{
  "functions": {
    "api/recognize.ts": { "maxDuration": 30 }
  }
}
```

- [ ] **Step 5: Rodar localmente e testar**

Run: `cd "/Users/victorferro/Projetos/Spot It" && npx vercel dev`
(Na primeira vez vai pedir pra logar e linkar o projeto — segue o prompt interativo.)

Em outro terminal, com uma imagem de teste em base64:
```bash
IMG_B64=$(base64 -i caminho/para/foto-carro.jpg)
curl -X POST http://localhost:3000/api/recognize \
  -H "Content-Type: application/json" \
  -d "{\"imageBase64\": \"$IMG_B64\"}"
```
Expected: JSON com `reconhecido: true` e dados do carro (se a foto for de um carro raro reconhecível).

- [ ] **Step 6: Configurar env var na Vercel**

No dashboard da Vercel (projeto linkado no passo 5) → Settings → Environment Variables → adiciona `ANTHROPIC_API_KEY` com o valor do `.env` local.

- [ ] **Step 7: Commit**

```bash
git add package.json api/recognize.ts vercel.json package-lock.json
git commit -m "feat: backend fino de reconhecimento de carro via Claude Vision"
```

---

### Task 3: Model `CarInfo` no app iOS

**Files:**
- Create: `Spot It/Spot It/Spot It/Models/CarInfo.swift`

**Interfaces:**
- Produces: `struct CarInfo: Codable` — usado pelas Tasks 4, 5, 6, 7.

- [ ] **Step 1: Criar o arquivo**

```swift
// CarInfo.swift
import Foundation

struct CarInfo: Codable {
    let reconhecido: Bool
    let modelo: String?
    let ano: Int?
    let motor: String?
    let raridade: Int?
    let valorEstimadoUsd: Double?
    let fatoInteressante: String?

    enum CodingKeys: String, CodingKey {
        case reconhecido
        case modelo
        case ano
        case motor
        case raridade
        case valorEstimadoUsd = "valor_estimado_usd"
        case fatoInteressante = "fato_interessante"
    }
}
```

- [ ] **Step 2: Adicionar o arquivo ao target no Xcode**

No Xcode: botão direito na pasta `Spot It` (dentro do projeto) → New Group → renomeia pra `Models` → arrasta `CarInfo.swift` pra dentro (ou New File > Swift File já direto na pasta certa).

- [ ] **Step 3: Verificar que compila**

Run: `Cmd + B` no Xcode.
Expected: "Build Succeeded", sem erros.

- [ ] **Step 4: Commit**

```bash
git add "Spot It/Spot It/Spot It/Models/CarInfo.swift"
git commit -m "feat: struct CarInfo pra decodificar resposta do backend"
```

---

### Task 4: `RecognizeService` — chamar o backend

**Files:**
- Create: `Spot It/Spot It/Spot It/Services/RecognizeService.swift`

**Interfaces:**
- Consumes: `CarInfo` (Task 3)
- Produces: `RecognizeService.recognize(imageData: Data) async throws -> CarInfo` — usado pela Task 6.

- [ ] **Step 1: Criar o arquivo**

```swift
// RecognizeService.swift
import Foundation

enum RecognizeError: Error {
    case invalidResponse
}

struct RecognizeService {
    // Troca pela URL da function depois do deploy (Task 2, Step 6 tem a env var configurada lá).
    // Em dev local, aponta pro `vercel dev` (http://localhost:3000).
    static let baseURL = URL(string: "https://spotit-backend.vercel.app")!

    static func recognize(imageData: Data) async throws -> CarInfo {
        let base64 = imageData.base64EncodedString()
        var request = URLRequest(url: baseURL.appendingPathComponent("api/recognize"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["imageBase64": base64])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw RecognizeError.invalidResponse
        }

        return try JSONDecoder().decode(CarInfo.self, from: data)
    }
}
```

- [ ] **Step 2: Adicionar ao target (pasta `Services`)**

Mesma mecânica da Task 3, Step 2.

- [ ] **Step 3: Verificar que compila**

Run: `Cmd + B`. Expected: "Build Succeeded".

- [ ] **Step 4: Commit**

```bash
git add "Spot It/Spot It/Spot It/Services/RecognizeService.swift"
git commit -m "feat: RecognizeService chama o backend de reconhecimento"
```

---

### Task 5: `SupabaseService` — upload de foto + salvar item

**Files:**
- Create: `Spot It/Spot It/Spot It/Services/SupabaseService.swift`

**Interfaces:**
- Consumes: `CarInfo` (Task 3)
- Produces:
  - `SupabaseService.uploadPhoto(imageData: Data) async throws -> String` (retorna URL pública)
  - `SupabaseService.saveWalletItem(car: CarInfo, fotoUrl: String, lat: Double?, lng: Double?) async throws -> Void`
  - `SupabaseService.fetchWalletItems() async throws -> [WalletItem]`
  - `struct WalletItem: Codable, Identifiable` (id, modelo, ano, raridade, valorEstimadoUsd, fotoUrl, createdAt)

  Usado pelas Tasks 6 e 7.

- [ ] **Step 1: Adicionar o Supabase Swift SDK**

No Xcode: File → Add Package Dependencies → cola a URL `https://github.com/supabase/supabase-swift` → Add Package → seleciona o produto `Supabase`.

- [ ] **Step 2: Criar o arquivo**

```swift
// SupabaseService.swift
import Foundation
import Supabase

struct WalletItem: Codable, Identifiable {
    let id: UUID
    let modelo: String
    let ano: Int?
    let raridade: Int
    let valorEstimadoUsd: Double
    let fotoUrl: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, modelo, ano, raridade
        case valorEstimadoUsd = "valor_estimado_usd"
        case fotoUrl = "foto_url"
        case createdAt = "created_at"
    }
}

struct SupabaseService {
    // Troca pelos valores reais do .env (Project URL e anon key do dashboard Supabase).
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://mevdvmjtkkcerkakzkch.supabase.co")!,
        supabaseKey: "PASTE_ANON_KEY_AQUI"
    )

    static func uploadPhoto(imageData: Data) async throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        try await client.storage.from("car-photos").upload(fileName, data: imageData)
        return try client.storage.from("car-photos").getPublicURL(path: fileName).absoluteString
    }

    static func saveWalletItem(car: CarInfo, fotoUrl: String, lat: Double?, lng: Double?) async throws {
        struct NewItem: Encodable {
            let modelo: String
            let ano: Int?
            let motor: String?
            let raridade: Int
            let valor_estimado_usd: Double
            let fato_interessante: String?
            let foto_url: String
            let lat: Double?
            let lng: Double?
        }

        let item = NewItem(
            modelo: car.modelo ?? "Desconhecido",
            ano: car.ano,
            motor: car.motor,
            raridade: car.raridade ?? 1,
            valor_estimado_usd: car.valorEstimadoUsd ?? 0,
            fato_interessante: car.fatoInteressante,
            foto_url: fotoUrl,
            lat: lat,
            lng: lng
        )

        try await client.from("wallet_items").insert(item).execute()
    }

    static func fetchWalletItems() async throws -> [WalletItem] {
        try await client.from("wallet_items")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }
}
```

- [ ] **Step 3: Criar bucket `car-photos` no Supabase**

No dashboard Supabase → Storage → New Bucket → nome `car-photos` → marca como público (pra `getPublicURL` funcionar sem assinatura).

- [ ] **Step 4: Substituir a anon key no código pelo valor real**

Copia o valor de `SUPABASE_ANON_KEY` do `.env` local e substitui `"PASTE_ANON_KEY_AQUI"` no arquivo. (É seguro — a anon key é feita pra ir no cliente.)

- [ ] **Step 5: Verificar que compila**

Run: `Cmd + B`. Expected: "Build Succeeded".

- [ ] **Step 6: Commit**

```bash
git add "Spot It/Spot It/Spot It/Services/SupabaseService.swift"
git commit -m "feat: SupabaseService faz upload de foto e CRUD da wallet"
```

---

### Task 6: `CaptureView` + `ResultView`

**Files:**
- Create: `Spot It/Spot It/Spot It/Views/CaptureView.swift`
- Create: `Spot It/Spot It/Spot It/Views/ResultView.swift`
- Modify: `Spot It/Spot It/Spot It/ContentView.swift` (adiciona TabView com aba Captura)

**Interfaces:**
- Consumes: `RecognizeService.recognize` (Task 4), `SupabaseService.uploadPhoto`/`saveWalletItem` (Task 5)

- [ ] **Step 1: Adicionar permissão de câmera no Info**

No Xcode: seleciona o projeto `Spot It` no navegador → target `Spot It` → aba **Info** → adiciona a key `Privacy - Camera Usage Description` com valor `"Precisamos da câmera pra identificar os carros que você fotografar."`

- [ ] **Step 2: Criar `CaptureView.swift`**

```swift
// CaptureView.swift
import SwiftUI
import UIKit

struct CaptureView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var carInfo: CarInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Identificando o carro...")
            } else {
                Button("Tirar foto") {
                    showCamera = true
                }
                .buttonStyle(.borderedProminent)
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $capturedImage)
        }
        .onChange(of: capturedImage) { _, newImage in
            guard let newImage else { return }
            Task { await recognize(newImage) }
        }
        .sheet(item: $carInfo) { info in
            ResultView(carInfo: info, image: capturedImage)
        }
    }

    private func recognize(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return }
        isLoading = true
        errorMessage = nil
        do {
            carInfo = try await RecognizeService.recognize(imageData: data)
        } catch {
            errorMessage = "Não foi possível identificar o carro. Tenta de novo."
        }
        isLoading = false
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
    }
}

extension CarInfo: Identifiable {
    var id: String { modelo ?? UUID().uuidString }
}
```

- [ ] **Step 3: Criar `ResultView.swift`**

```swift
// ResultView.swift
import SwiftUI

struct ResultView: View {
    let carInfo: CarInfo
    let image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    }

                    if carInfo.reconhecido {
                        Text(carInfo.modelo ?? "").font(.title2).bold()
                        if let ano = carInfo.ano { Text("Ano: \(ano)") }
                        if let motor = carInfo.motor { Text("Motor: \(motor)") }
                        if let raridade = carInfo.raridade { Text("Raridade: \(raridade)/10") }
                        if let valor = carInfo.valorEstimadoUsd {
                            Text("Valor estimado: $\(valor, specifier: "%.0f")")
                        }
                        if let fato = carInfo.fatoInteressante {
                            Text(fato).font(.footnote).foregroundStyle(.secondary)
                        }

                        Button(isSaving ? "Salvando..." : "Salvar na Wallet") {
                            Task { await save() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaving)
                    } else {
                        Text("Não conseguimos identificar esse carro.")
                    }

                    if let saveError {
                        Text(saveError).foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        guard let image, let data = image.jpegData(compressionQuality: 0.7) else { return }
        isSaving = true
        saveError = nil
        do {
            let url = try await SupabaseService.uploadPhoto(imageData: data)
            try await SupabaseService.saveWalletItem(car: carInfo, fotoUrl: url, lat: nil, lng: nil)
            dismiss()
        } catch {
            saveError = "Não foi possível salvar. Tenta de novo."
        }
        isSaving = false
    }
}
```

- [ ] **Step 4: Transformar `ContentView` numa TabView**

```swift
// ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CaptureView()
                .tabItem { Label("Captura", systemImage: "camera") }

            WalletView()
                .tabItem { Label("Wallet", systemImage: "wallet.pass") }
        }
    }
}

#Preview {
    ContentView()
}
```

(`WalletView` ainda não existe — vem na Task 7. Build vai falhar até lá, tudo bem, é o próximo passo imediato.)

- [ ] **Step 5: Adicionar os arquivos ao target**

Mesma mecânica das tasks anteriores — cria grupo `Views`, arrasta os 2 arquivos novos.

- [ ] **Step 6: Commit**

```bash
git add "Spot It/Spot It/Spot It/Views/CaptureView.swift" "Spot It/Spot It/Spot It/Views/ResultView.swift" "Spot It/Spot It/Spot It/ContentView.swift"
git commit -m "feat: telas de Captura e Resultado"
```

---

### Task 7: `WalletView`

**Files:**
- Create: `Spot It/Spot It/Spot It/Views/WalletView.swift`

**Interfaces:**
- Consumes: `SupabaseService.fetchWalletItems` (Task 5), `WalletItem` (Task 5)

- [ ] **Step 1: Criar o arquivo**

```swift
// WalletView.swift
import SwiftUI

struct WalletView: View {
    @State private var items: [WalletItem] = []
    @State private var isLoading = true

    var total: Double {
        items.reduce(0) { $0 + $1.valorEstimadoUsd }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Total: $\(total, specifier: "%.0f")")
                        .font(.title2).bold()
                }

                ForEach(items) { item in
                    VStack(alignment: .leading) {
                        Text(item.modelo).font(.headline)
                        Text("$\(item.valorEstimadoUsd, specifier: "%.0f") · Raridade \(item.raridade)/10")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Wallet")
            .task { await load() }
            .refreshable { await load() }
            .overlay {
                if isLoading && items.isEmpty {
                    ProgressView()
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        items = (try? await SupabaseService.fetchWalletItems()) ?? []
        isLoading = false
    }
}
```

- [ ] **Step 2: Adicionar ao target (pasta `Views`)**

- [ ] **Step 3: Build completo**

Run: `Cmd + B`. Expected: "Build Succeeded" (agora com `ContentView` referenciando `WalletView`).

- [ ] **Step 4: Commit**

```bash
git add "Spot It/Spot It/Spot It/Views/WalletView.swift"
git commit -m "feat: tela de Wallet lista itens e soma valor total"
```

---

### Task 8: Verificação manual end-to-end

**Files:** nenhum (só verificação)

- [ ] **Step 1: Rodar `vercel dev` local (ou usar a URL de produção já deployada)**

- [ ] **Step 2: Rodar o app no simulador ou num iPhone físico conectado**

(Câmera não funciona no simulador — pra testar de verdade, conecta o iPhone físico via cabo, seleciona ele como destino no Xcode, e roda com `Cmd + R`.)

- [ ] **Step 3: Fluxo completo**

1. Aba Captura → Tirar foto → aponta pra uma foto de um carro raro (impressa ou na tela de outro dispositivo)
2. Confere se aparece o resultado com modelo/ano/valor coerentes
3. Toca "Salvar na Wallet"
4. Vai na aba Wallet → confere se o item aparece e o total bate

- [ ] **Step 4: Testar caso de carro não identificado**

Tira foto de algo que não é carro (ex: uma parede) → confere se aparece "Não conseguimos identificar esse carro" e nada é salvo.

- [ ] **Step 5: Registrar qualquer problema ou ideia nova em `insights/README.md`**

Se durante o teste surgir alguma ideia de melhoria que não vamos aplicar agora, adiciona lá antes de esquecer.

---

## Self-Review

- **Cobertura da spec**: fluxo completo (captura → reconhecimento → wallet com soma) coberto pelas Tasks 1-8. Erro de "não reconhecido" tratado na Task 6/8. Localização (lat/lng) deixada como `nil` nesta fatia — o parâmetro já existe em `saveWalletItem` pra ser preenchido quando a Task de permissão de localização entrar (fora de escopo aqui, spec não pede isso na wallet além do campo existir).
- **Placeholders**: nenhum "TBD"/"depois" — a única substituição manual pendente é a anon key real no Step 4 da Task 5, que é uma ação explícita do usuário (colar valor do `.env`), não um placeholder de código.
- **Consistência de tipos**: `CarInfo` (Task 3) usado igual em `RecognizeService` (Task 4), `ResultView`/`CaptureView` (Task 6) e `SupabaseService.saveWalletItem` (Task 5). `WalletItem` (Task 5) usado igual em `WalletView` (Task 7).
