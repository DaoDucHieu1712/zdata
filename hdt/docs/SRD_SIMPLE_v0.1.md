# Tài liệu Thiết kế Phần mềm (SRD)
## BongStudio Simple — v0.1
**Phiên bản tài liệu:** 0.1
**Nguồn tham chiếu:** SRD_v1.4.md (bản đầy đủ) — rút gọn phạm vi
**SRS tương ứng:** `docs/SRS_SIMPLE_v0.1.md`
**Ngày:** 2026-07-27
**Tóm tắt:** Thiết kế cho phiên bản đơn giản: **ứng dụng React thuần (SPA)**, **chạy local
cá nhân**, tạo phim/vlog/video bằng **Cloud AI**. Không có FastAPI, Celery, Redis, Ollama,
ComfyUI, F5-TTS, và **không có cơ sở dữ liệu máy chủ (MariaDB/…)**. Dữ liệu lưu trong trình
duyệt (IndexedDB/localStorage); AI gọi trực tiếp tới Cloud AI Provider; ghép/xuất video bằng
`ffmpeg.wasm`. **React Flow** được dùng cho hai màn hình node-graph: **Storyboard phân cảnh**
và **Cấu hình pipeline AI**.

---

## Mục lục

1. [Kiến trúc hệ thống](#1-kiến-trúc-hệ-thống)
2. [Thiết kế Frontend](#2-thiết-kế-frontend)
3. [Thiết kế tầng dịch vụ (client services)](#3-thiết-kế-tầng-dịch-vụ-client-services)
4. [Thiết kế dữ liệu (IndexedDB)](#4-thiết-kế-dữ-liệu-indexeddb)
5. [Thiết kế pipeline AI](#5-thiết-kế-pipeline-ai)
6. [Hàng đợi Job & thời gian thực](#6-hàng-đợi-job--thời-gian-thực)
7. [Lưu trữ & Xuất video](#7-lưu-trữ--xuất-video)
8. [Bảo mật](#8-bảo-mật)
9. [Triển khai](#9-triển-khai)

---

## 1. Kiến trúc hệ thống

### 1.1 Tổng quan

```
┌───────────────────────────────────────────────────────────────┐
│                    Trình duyệt người dùng                      │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  React 18 SPA (Vite)                                    │  │
│  │   ├── Zustand stores (project, scenes, jobs, config, ui)│  │
│  │   ├── UI phân cảnh (danh sách/lưới thẻ cảnh)            │  │
│  │   ├── Trình soạn kịch bản                               │  │
│  │   ├── aiClient (adapter gọi Cloud AI)                   │  │
│  │   ├── jobQueue (hàng đợi tác vụ AI phía client)         │  │
│  │   ├── storage (IndexedDB qua Dexie)                     │  │
│  │   └── exporter (ffmpeg.wasm)                            │  │
│  └───────────────────────────┬─────────────────────────────┘  │
└──────────────────────────────┼────────────────────────────────┘
                               │ HTTPS (fetch)
        ┌──────────────────────┼───────────────────────┐
        ▼            ▼          ▼           ▼
   Cloud LLM   Cloud Image  Cloud Video  Cloud TTS
   (kịch bản)  (t2i)        (i2v/t2v)    (giọng nói)
```

### 1.2 Nguyên tắc thiết kế

- **Client-only:** không có máy chủ ứng dụng riêng; SPA tĩnh + Cloud AI.
- **Cloud-only:** mọi suy luận AI đều trên đám mây; không có đường dẫn AI cục bộ.
- **Adapter hóa provider:** mọi lời gọi AI đi qua một entrypoint `aiClient.call(stage, payload)`
  để mã tính năng không phụ thuộc vào provider cụ thể.
- **Lưu cục bộ trước:** dữ liệu và asset lưu trong IndexedDB để làm việc mượt và cho phép
  ghép/xuất offline (sau khi asset đã tải về).
- **Job đơn giản, tuần tự:** hàng đợi Job chạy trong trình duyệt, không cần Celery/Redis.

### 1.3 Công nghệ

| Mối quan tâm | Thư viện / Công cụ |
|---|---|
| Framework | React 18 |
| Bundler | Vite |
| Styling | TailwindCSS |
| State toàn cục | Zustand |
| Canvas node-graph | **React Flow (`@xyflow/react`)** — storyboard + cấu hình pipeline AI |
| Lưu trữ | IndexedDB (qua Dexie.js) + localStorage (config) — **không dùng MariaDB/DB máy chủ** |
| HTTP | `fetch` (native) |
| Ghép/xuất video | `@ffmpeg/ffmpeg` (ffmpeg.wasm) |
| Soạn thảo kịch bản | textarea nâng cao / Monaco (tùy chọn) |

> So với v1.4: giữ **React Flow** cho canvas, nhưng loại bỏ FastAPI, SQLModel/Alembic,
> Celery, Redis, WebSocket máy chủ **và cơ sở dữ liệu máy chủ**. Cập nhật thời gian thực dùng
> callback trong trình duyệt (không WS).

---

## 2. Thiết kế Frontend

### 2.1 Bố cục ứng dụng

```
App
├── ProjectDashboard          — danh sách / tạo / mở dự án
└── ProjectWorkspace (theo dự án)
    ├── Toolbar               — Tạo kịch bản, Tạo phân cảnh, Sinh tất cả, Xuất video, Cấu hình AI
    ├── ScriptPanel           — nhập ý tưởng, sinh & sửa kịch bản
    ├── StoryboardCanvas      — canvas React Flow (khu vực chính)
    │   ├── StoryboardNode    — node mỗi cảnh (ảnh xem trước, trạng thái, nút hành động)
    │   └── TransitionEdge    — edge nối cảnh (thứ tự chuyển cảnh)
    ├── SceneEditorPanel      — panel chỉnh sửa cảnh (prompt, thoại, media_mode, thời lượng)
    ├── AIPipelineCanvas      — canvas React Flow cấu hình AI (công đoạn ↔ provider)
    │   ├── StageNode         — node công đoạn: LLM / Image / Video / TTS
    │   ├── ProviderNode      — node Cloud AI Provider (form + nút Kiểm tra kết nối)
    │   └── RoutingEdge       — edge gán provider cho công đoạn
    └── ExportModal           — chọn độ phân giải/fps, chạy ffmpeg.wasm, tải về
```

### 2.2 Bố cục Zustand store

```typescript
// projectStore
{
  project: Project | null
  script: Script | null
  scenes: Scene[]
  characters: Character[]        // tùy chọn
  actions: { loadProject, saveScene, addScene, removeScene, reorderScenes, ... }
}

// canvasStore   (React Flow — storyboard)
{
  nodes: Node[]                  // node cảnh (position + scene metadata)
  edges: Edge[]                  // edge chuyển cảnh (suy ra `order` để ghép/xuất)
  viewport: Viewport
  actions: { addNode, removeNode, onConnect, saveLayout }
}

// jobStore
{
  jobs: Record<string, Job>              // keyed by job_id
  queue: string[]                        // hàng đợi job_id chờ chạy
  running: string | null                 // job đang chạy (chạy tuần tự)
  actions: { enqueue, onJobUpdate, onJobDone, onJobFailed }
}

// configStore   (đồng bộ với localStorage) — canvas cấu hình pipeline AI
{
  providers: CloudProviderConfig[]       // api_key luôn ở dạng che trong state hiển thị
  // Đồ thị React Flow cấu hình AI:
  pipelineNodes: Node[]                  // 4 StageNode + N ProviderNode
  pipelineEdges: Edge[]                  // RoutingEdge: stage -> provider
  // stageSelection được suy ra từ pipelineEdges (mỗi stage nối tới đúng 1 provider hợp lệ)
  stageSelection: Record<'llm'|'image'|'video'|'tts', string | null>  // provider_id
  actions: { saveProvider, deleteProvider, onConnectRouting, testProvider }
}

// uiStore
{
  editorOpen: boolean
  editorSceneId: string | null
  aiPipelineOpen: boolean        // mở canvas cấu hình AI
  exportOpen: boolean
}
```

### 2.3 Component StoryboardNode (React Flow)

```
StoryboardNode
├── Header      — số thứ tự, tiêu đề, badge media_mode (🎥 / 🖼), badge trạng thái
├── Preview     — ảnh/video xem trước (hoặc placeholder), badge thời lượng
├── Meta        — mô tả ngắn (prompt rút gọn), lời thoại (2 dòng đầu)
├── Progress    — thanh tiến độ (khi Job đang chạy)
├── Handles     — cổng nối edge (source/target) để nối thứ tự chuyển cảnh
└── Actions     — nút theo trạng thái:
                   chưa có ảnh:  ⚡ Sinh ảnh · 📁 Tải ảnh lên
                   có ảnh:       🎥 Sinh video · 🔊 Sinh giọng · ✏️ Sửa
                   xong:         🔁 Sinh lại ảnh · 🔁 Sinh lại video
                   lỗi:          🔁 Thử lại
```

Cấu hình React Flow (storyboard): `onNodeDragStop` → `saveLayout()` (debounce);
`onConnect` → tạo `TransitionEdge`; `order` ghép/xuất suy ra từ chuỗi edge (FR-SB-02b).

### 2.4 Component AIPipelineCanvas (React Flow) — cấu hình AI

```
AIPipelineCanvas
├── StageNode × 4     — LLM · Image · Video · TTS (mỗi node 1 handle target)
├── ProviderNode × N  — mỗi provider: name, category, endpoint_url, model_id,
│                        ô nhập/che api_key, nút "Kiểm tra kết nối", đèn trạng thái
└── RoutingEdge       — nối StageNode → ProviderNode (gán provider cho công đoạn)
```

**Quy tắc nối (`onConnectRouting`):**
- Chỉ cho nối `StageNode(category=X)` → `ProviderNode(category=X)`; sai `category` → từ chối,
  hiển thị edge đỏ tạm thời + toast lỗi (FR-MC-03).
- Mỗi StageNode chỉ giữ **một** RoutingEdge; nối dây mới sẽ thay dây cũ.
- `stageSelection` được tính lại từ tập `pipelineEdges` mỗi khi đồ thị đổi.
- Node provider đổi màu theo kết quả "Kiểm tra kết nối": xanh = OK, đỏ = lỗi (FR-MC-05).

### 2.5 Cập nhật thời gian thực (không WebSocket)

Vì không có backend, tiến độ được cập nhật bằng callback ngay trong trình duyệt:

```typescript
await aiClient.call('image', payload, {
  onProgress: (p, step) => jobStore.onJobUpdate(jobId, p, step),
})
jobStore.onJobDone(jobId, resultBlob)
```

Provider hỗ trợ streaming (SSE/chunked) được đọc dần và đẩy tiến độ; provider không stream thì
cập nhật tiến độ theo trạng thái (`queued` → `running` → `done`).

---

## 3. Thiết kế tầng dịch vụ (client services)

Tất cả nằm trong trình duyệt, dưới `src/services/`:

```
src/services/
├── aiClient.ts        — entrypoint chung: call(stage, payload, opts)
├── adapters/
│   ├── llmAdapter.ts   — chuẩn hóa request/response cho Cloud LLM
│   ├── imageAdapter.ts — text-to-image
│   ├── videoAdapter.ts — image/text-to-video
│   └── ttsAdapter.ts   — text-to-speech
├── scriptService.ts   — generateScript(), autoBreakdown()  (dùng llmAdapter)
├── jobQueue.ts         — hàng đợi tuần tự, retry, hủy
├── storage.ts          — Dexie: CRUD project/scene/asset
├── configStore.ts      — quản lý provider + mã hóa/che API key
└── exporter.ts         — ffmpeg.wasm: ghép cảnh + trộn audio
```

### 3.1 Entrypoint `aiClient.call`

```typescript
type Stage = 'llm' | 'image' | 'video' | 'tts'

async function call(stage: Stage, payload: any, opts?: CallOpts): Promise<Blob | string> {
  const providerId = configStore.stageSelection[stage]
  if (!providerId) throw new ConfigError(`Chưa cấu hình Cloud AI cho công đoạn: ${stage}`)
  const provider = configStore.getProvider(providerId)   // giải mã api_key khi gọi
  const adapter  = ADAPTERS[stage]                        // llm/image/video/tts
  return adapter.run(provider, payload, opts)             // chuẩn hóa + fetch HTTPS
}
```

Mỗi adapter chịu trách nhiệm dịch payload chung sang định dạng riêng của provider và dịch
ngược kết quả về `Blob` (ảnh/video/audio) hoặc `string` (văn bản kịch bản).

### 3.2 `scriptService`

- `generateScript(premise, toneTags, length)` → gọi `aiClient.call('llm', …)`, trả văn bản
  kịch bản (FR-SG-01..02); hỗ trợ đọc stream (FR-SG-04).
- `autoBreakdown(scriptText, projectType)` → gọi LLM với prompt yêu cầu trả **JSON danh sách
  cảnh** (`title`, `prompt`, `duration_sec`, `dialogue`); validate và chèn vào `scenes`
  (FR-SB-04). Với `vlog` áp dụng khuôn "một người dẫn + thuyết minh" (FR-SB-05).

---

## 4. Thiết kế dữ liệu (IndexedDB)

**Không dùng MariaDB / cơ sở dữ liệu máy chủ** (theo yêu cầu: dùng cá nhân, chạy local). Dữ
liệu lưu trong trình duyệt bằng Dexie.js (IndexedDB). Các bảng (object stores):

```typescript
db.version(1).stores({
  projects:   'id, type, updated_at',
  scripts:    'project_id',
  scenes:     'id, project_id, order',
  assets:     'scene_id',            // blob ảnh/video/audio
  characters: 'id, project_id',      // tùy chọn
  layouts:    'project_id',          // canvas React Flow storyboard (nodes/edges/viewport)
})
// Cấu hình Cloud AI + đồ thị pipeline AI lưu ở localStorage, KHÔNG nằm trong bản xuất dự án.
```

> Lược đồ được thiết kế phẳng, dễ **chuyển sang MariaDB** về sau (mỗi object store ↔ một
> bảng) nếu cần chạy đa máy/đồng bộ — nhưng nằm ngoài phạm vi v0.1.

### 4.1 `projects`
| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | string PK | uuid |
| `name` | string | |
| `type` | string | `film` \| `vlog` \| `video` |
| `language` | string | mặc định `vi` |
| `created_at` / `updated_at` | ISO datetime | |

### 4.2 `scripts`
| Cột | Kiểu | Ghi chú |
|---|---|---|
| `project_id` | string PK/FK | → projects |
| `premise` | string | ý tưởng gốc |
| `tone_tags` | string[] | |
| `full_text` | string | kịch bản hiện tại (sửa được) |
| `updated_at` | ISO datetime | |

### 4.3 `scenes`
| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | string PK | `scene_001` |
| `project_id` | string FK | → projects |
| `order` | int | thứ tự hiển thị/ghép |
| `title` | string | |
| `prompt` | string | mô tả hình ảnh (t2i) |
| `camera_note` | string? | gợi ý chuyển động cho video |
| `media_mode` | string | `video` (mặc định) \| `image` |
| `duration_sec` | int | `video`: giới hạn theo model; `image`: tự do (mặc định 8) |
| `dialogue` | string? | lời thoại/thuyết minh cho TTS |
| `status` | string | `queued\|running\|done\|error` |

### 4.4 `assets`
| Cột | Kiểu | Ghi chú |
|---|---|---|
| `scene_id` | string PK/FK | → scenes |
| `image_blob` | Blob? | ảnh đã sinh/tải lên |
| `image_status` | string | `queued\|running\|done\|error` |
| `image_source` | string | `ai` \| `manual` |
| `video_blob` | Blob? | clip (chỉ `video` mode); null ở `image` mode |
| `video_status` | string | `queued\|running\|done\|error\|skipped` |
| `audio_blob` | Blob? | giọng đọc |
| `audio_status` | string | |

### 4.5 `characters` (tùy chọn)
| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | string PK | |
| `project_id` | string FK | |
| `name` | string | |
| `description` | string | mô tả hình ảnh, chèn vào prompt cảnh để nhất quán |

### 4.6 Cấu hình Cloud AI + đồ thị pipeline (localStorage)
```typescript
interface CloudProviderConfig {
  id: string
  name: string
  category: 'llm' | 'image' | 'video' | 'tts'
  endpoint_url: string          // bắt buộc https://
  api_key_enc: string           // mã hóa nhẹ (Web Crypto); không lưu plaintext
  model_id: string
  node_position: { x: number; y: number }   // vị trí ProviderNode trên canvas cấu hình
}

// Đồ thị React Flow của màn hình cấu hình pipeline AI (FR-MC-03)
interface PipelineGraph {
  stageNodePositions: Record<'llm'|'image'|'video'|'tts', { x: number; y: number }>
  edges: { stage: 'llm'|'image'|'video'|'tts'; provider_id: string }[]  // RoutingEdge
}

// stageSelection suy ra từ PipelineGraph.edges (mỗi stage → 1 provider hợp lệ)
interface StageSelection {
  llm: string | null; image: string | null; video: string | null; tts: string | null
}
```

`api_key_enc` không bao giờ nằm trong node data của React Flow (tránh lộ khi serialize đồ
thị); node provider chỉ tham chiếu `provider_id`, key được đọc riêng khi gọi Cloud AI.

---

## 5. Thiết kế pipeline AI

### 5.1 Pipeline sinh một cảnh

```
Cảnh (video mode):
  prompt ─► Cloud Image AI ─► image_blob ─► Cloud Video AI ─► video_blob
  dialogue ─► Cloud TTS ─► audio_blob         (chạy song song sau khi có ảnh)

Cảnh (image mode):
  prompt ─► Cloud Image AI ─► image_blob      (không sinh video)
  dialogue ─► Cloud TTS ─► audio_blob
```

- **Sinh ảnh** (`imageAdapter`): gửi `prompt` (+ mô tả nhân vật nếu có) → nhận ảnh.
- **Sinh video** (`videoAdapter`): ưu tiên image-to-video từ `image_blob` + `camera_note`;
  nếu provider chỉ hỗ trợ text-to-video thì dùng `prompt`. Thời lượng bị kẹp theo giới hạn
  model của provider (SRS FR-GP-04).
- **Sinh audio** (`ttsAdapter`): gửi `dialogue` + voice/tốc độ → nhận audio.

### 5.2 Tạo kịch bản & phân cảnh tự động

- `generateScript`: một lời gọi LLM (có thể stream) trả văn bản kịch bản.
- `autoBreakdown`: gọi LLM với system prompt yêu cầu trả JSON mảng cảnh; parse + validate
  (bỏ cảnh thiếu `prompt`), gán `order` tăng dần, chèn vào `scenes`.

### 5.3 Xử lý lỗi

Mỗi adapter chuẩn hóa lỗi provider về dạng `{ code, message }`; jobQueue đánh dấu Job `error`,
hiển thị nút "Thử lại". Lỗi một cảnh không dừng các cảnh khác (SRS NFR-R-01).

---

## 6. Hàng đợi Job & thời gian thực

- `jobQueue` là hàng đợi **tuần tự** trong trình duyệt (chạy từng job một để tránh vượt giới
  hạn rate của provider). Có thể nâng lên chạy song song giới hạn (concurrency ≤ 2) ở P2.
- "Sinh tất cả" (FR-GP-08) đẩy toàn bộ cảnh chưa hoàn thành vào hàng đợi.
- Tiến độ cập nhật qua callback → `jobStore` → re-render SceneCard (không WebSocket).
- Job có thể **hủy**: hủy job đang chờ trong hàng đợi; job đang chạy sẽ `AbortController` hủy
  fetch nếu provider hỗ trợ.

```typescript
interface Job {
  id: string
  scene_id: string | null
  type: 'gen_script' | 'gen_image' | 'gen_video' | 'gen_audio'
  status: 'queued' | 'running' | 'done' | 'error' | 'cancelled'
  progress: number      // 0.0 – 1.0
  step?: string
  error?: string
}
```

---

## 7. Lưu trữ & Xuất video

### 7.1 Lưu trữ

- Asset (ảnh/video/audio) lưu dạng `Blob` trong IndexedDB, tham chiếu qua `URL.createObjectURL`
  khi hiển thị.
- Tự động lưu sau mỗi thay đổi (SRS NFR-R-02).
- Xuất/nhập dự án (FR-PM-04): serialize project + scenes + script ra JSON; **không** kèm
  API key.

### 7.2 Xuất video bằng ffmpeg.wasm

```
exporter.export(projectId, { resolution, fps }):
  1. Lấy các cảnh theo `order`.
  2. Với cảnh image mode: ffmpeg -loop 1 -i image.png -t duration_sec → segment.mp4
     Với cảnh video mode: dùng video_blob (chuẩn hóa fps/độ phân giải).
  3. Trộn audio giọng đọc cho từng segment; trộn BGM (nếu có) ở mức thấp hơn.
  4. concat các segment → final.mp4
  5. Trả Blob để tải về (FR-EX-02).
```

- Độ phân giải/fps theo lựa chọn người dùng (FR-EX-03).
- Với video dài, cho phép xuất từng cảnh (FR-EX-04) để tránh giới hạn bộ nhớ trình duyệt.

---

## 8. Bảo mật

- **API key**: mã hóa nhẹ bằng Web Crypto trước khi lưu localStorage; giải mã chỉ khi gọi
  Cloud AI; hiển thị dạng che `sk-****1234` (SRS FR-MC-03, NFR-S-01).
- **Chỉ HTTPS**: từ chối endpoint không phải `https://` (NFR-S-02).
- **Cảnh báo lộ key phía client**: khi gọi Cloud AI trực tiếp từ trình duyệt, key nằm trong
  request client-side. Với môi trường cần bảo mật cao, tài liệu khuyến nghị đặt một **proxy
  mỏng** (serverless function) giữ key phía máy chủ — nằm **ngoài phạm vi MVP v0.1** nhưng
  được thiết kế cắm-thêm: chỉ cần đổi `endpoint_url` của provider sang URL proxy.
- **CORS**: nếu provider không cho phép gọi từ trình duyệt, người dùng phải dùng proxy.

---

## 9. Triển khai

- Build tĩnh bằng Vite (`vite build`) → thư mục `dist/`.
- Triển khai lên bất kỳ **static host** nào (Netlify, Vercel static, GitHub Pages, S3…).
- Không cần máy chủ ứng dụng, cơ sở dữ liệu, hay dịch vụ nền (SRS NFR-C-01).
- Yêu cầu: trình duyệt hiện đại có hỗ trợ IndexedDB và WebAssembly (cho ffmpeg.wasm).

---

### Phụ lục A — Đối chiếu với bản đầy đủ v1.4

| Chủ đề | v1.4 (đầy đủ) | v0.1 (Simple) |
|---|---|---|
| Kiến trúc | React + FastAPI + Celery + Redis + SQLite | Chỉ React (SPA), chạy local, lưu trong trình duyệt |
| Cơ sở dữ liệu | SQLite (máy chủ) | **Không DB máy chủ** — IndexedDB/localStorage (MariaDB bị loại) |
| Canvas React Flow | Storyboard | **Storyboard + Cấu hình pipeline AI** (node-graph) |
| Cấu hình AI | Form + routing local/cloud/hybrid | **Giao diện node-graph React Flow**, chỉ Cloud |
| AI | Local + Cloud + Hybrid | **Chỉ Cloud** |
| Sinh kịch bản | Ollama/Cloud, có bản nháp & revision | Cloud LLM, sửa văn bản đơn giản |
| Nhân vật | Sheet 8 góc, biểu cảm, cận mặt, tóc | (Tùy chọn) tên + mô tả để nhất quán prompt |
| Vật thể/Animation | Có (Object/Animation material) | Không |
| Kiểm duyệt/Phê duyệt/QA | Có | Không |
| Quản lý sản xuất (khách hàng, ngân sách, mốc) | Có | Không |
| Xuất video | FFmpeg phía máy chủ | ffmpeg.wasm phía trình duyệt |
| Thời gian thực | WebSocket máy chủ | Callback trong trình duyệt |
