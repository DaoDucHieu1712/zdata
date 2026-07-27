# task_0000 — Overview & Task Index (BongStudio Simple v0.1)

**Source docs:** `docs/SRS_SIMPLE_v0.1.md`, `docs/SRD_SIMPLE_v0.1.md`
**Conventions:** `AGENTS.md` (feature-folder architecture, TS/naming/styling rules)

## Product in one line
A **client-only React SPA** to turn an idea → script → storyboard → images/video → voice → exported MP4, using **Cloud AI providers** configured through a visual React Flow node-graph. No backend, no server DB.

## Stack reconciliation (read before coding)
The SRS/SRD describe a client-only app; the repo scaffold has an Axios client at `https://localhost:9000`. We follow the **docs**:

| Concern | Decision |
|---|---|
| Persistence | IndexedDB via **Dexie** (`projects`, `scripts`, `scenes`, `assets`, `characters`, `layouts`) + `localStorage` for AI config |
| Async-state boundary | Keep **TanStack Query** conventions. `fetchers.ts` call the **local services** (Dexie / aiClient) instead of Axios. `queries.ts`/`mutations.ts` unchanged in spirit. |
| AI calls | `src/services/aiClient.ts` + per-stage adapters, called directly over HTTPS from the browser |
| Video export | `@ffmpeg/ffmpeg` (ffmpeg.wasm) in-browser |
| API keys | Web Crypto light encryption in localStorage; never plaintext, never in exports |
| UI state | Zustand `ui-store` + per-feature stores (already the pattern) |
| Existing `lib/api-client.ts` | Keep only if a thin proxy is later used (§8). Not required for MVP. |

## New dependencies (need approval per AGENTS.md rule 5)
- `dexie` — IndexedDB wrapper
- `@ffmpeg/ffmpeg`, `@ffmpeg/util` — in-browser video export
> `@xyflow/react`, `react-hook-form`, `zod`, `zustand`, `@tanstack/react-query`, `axios` already present.

## Reuse what exists
- `components/common/data-table.tsx`, `search-panel.tsx`, `app-shell.tsx`, `status-badge.tsx`, `bulk-action-bar.tsx`
- `components/ui/*` (input, select, textarea, datetime-input, radio, checkbox, range-input)
- `features/storyboard/*` — already a React Flow scaffold → evolve into the Scene storyboard (task_0008)
- `features/workflow/*` — React Flow scaffold → basis for the AI pipeline canvas (task_0004)
- `lib/create-list-store.ts`, `lib/create-query-keys.ts`, `lib/query-client.ts`

## Task index & dependency order
| Task | Title | Priority | Depends on | FRs |
|---|---|---|---|---|
| 0001 | Storage layer (Dexie) | P1 | — | FR-PM-02, §4 |
| 0002 | Project management feature | P1 | 0001 | FR-PM-01..05 |
| 0003 | Cloud AI provider config + key vault | P1 | 0001 | FR-MC-01/04/06, NFR-S |
| 0004 | AI pipeline canvas (React Flow) | P1 | 0003 | FR-MC-03/05/07, FR-MC-02 |
| 0005 | aiClient + stage adapters | P1 | 0003 | SRD §3.1/§5 |
| 0006 | Job queue + realtime progress | P1 | 0005 | FR-GP-05, §6, NFR-P/R |
| 0007 | Script generation panel | P1 | 0002,0005 | FR-SG-01..06 |
| 0008 | Storyboard canvas (scenes) | P1 | 0002 | FR-SB-01..03/02b |
| 0009 | Auto breakdown + characters | P1 | 0007,0008 | FR-SB-04..06 |
| 0010 | Scene editor panel | P1 | 0008 | FR-SB-03 |
| 0011 | Image & video generation | P1 | 0006,0008 | FR-GP-01..08 |
| 0012 | TTS / audio | P1 | 0006,0008 | FR-VA-01..04 |
| 0013 | Video export (ffmpeg.wasm) | P1 | 0011,0012 | FR-EX-01..04 |
| 0014 | Project workspace shell & routing | P1 | 0002 | §2.1, §5 |
| 0015 | Project JSON import/export | P2 | 0001,0002 | FR-PM-04, NFR-S-01 |
| 0016 | NFR hardening & i18n (vi) | P2 | many | NFR-* |

## Definition of Done (global)
- No `any`; types live in feature `types/`; public API via `index.ts` barrel.
- Tailwind + `cn()`; grid-based layouts; one component per kebab-case file.
- `npm run lint` and `tsc` clean.
- Each task's acceptance criteria met and manually verified in-browser.
