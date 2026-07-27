# task_0001 — Storage layer (IndexedDB via Dexie)

**Priority:** P1  **Depends on:** —  **FRs:** FR-PM-02, NFR-R-02, SRD §4

## Goal
A single client-side persistence layer for all project data using Dexie (IndexedDB). Everything else builds on this.

## Scope
- Add `dexie` dependency (needs approval — see task_0000).
- Create `src/lib/db.ts` defining the Dexie schema (SRD §4):
  ```ts
  db.version(1).stores({
    projects:   'id, type, updated_at',
    scripts:    'project_id',
    scenes:     'id, project_id, order',
    assets:     'scene_id',
    characters: 'id, project_id',
    layouts:    'project_id',
  })
  ```
- Create `src/services/storage.ts` with typed CRUD helpers per store:
  - `projects`: `create/get/list/rename/remove`
  - `scripts`: `getByProject/upsert`
  - `scenes`: `listByProject (ordered)/get/upsert/remove/reorder`
  - `assets`: `getByScene/upsert (blob fields + statuses)`
  - `characters`: `listByProject/upsert/remove`
  - `layouts`: `getByProject/upsert` (React Flow nodes/edges/viewport)
- Blob-safe: store `Blob` directly; expose helper `objectUrlFor(blob)` (revocation handled by caller/hook).

## Types (global — `src/types/` or feature-local later)
Define `Project`, `Script`, `Scene`, `Asset`, `Character`, `CanvasLayout` matching SRD §4.1–4.5 exactly (statuses as string unions).

## Acceptance criteria
- All stores created; DB opens without migration errors in a fresh browser.
- CRUD helpers round-trip data (write → read equal).
- Scenes returned sorted by `order`.
- No React imports in `storage.ts` (pure async service).

## Notes
- This is the "fetcher" backend that feature `fetchers.ts` will call instead of Axios.
- Auto-save (NFR-R-02) is realized by callers writing on every change; keep writes cheap.
