# task_0006 — Job queue + realtime progress

**Priority:** P1  **Depends on:** 0005  **FRs:** FR-GP-05, FR-GP-08, NFR-P-01, NFR-P-02, NFR-R-01, SRD §6

## Goal
A sequential in-browser job queue that runs AI calls one at a time, streams progress to the UI via callbacks (no WebSocket), supports retry and cancel.

## Scope
- `src/services/jobQueue.ts` — sequential runner: `enqueue(job)`, internal loop runs next when idle, `AbortController` per running job, retry.
- `src/stores/job-store.ts` (or `features/jobs/store.ts`) — Zustand:
  ```ts
  { jobs: Record<string, Job>, queue: string[], running: string | null,
    actions: { enqueue, onJobUpdate, onJobDone, onJobFailed, cancel, retry } }
  ```
  `Job`: `{ id, scene_id|null, type:'gen_script'|'gen_image'|'gen_video'|'gen_audio', status:'queued'|'running'|'done'|'error'|'cancelled', progress:0..1, step?, error? }` (SRD §6).

## Behavior
- Runs **tuần tự** (one at a time) to respect provider rate limits (P2: optional concurrency ≤ 2).
- Progress flows: `aiClient` `onProgress` → `jobStore.onJobUpdate` → component re-render (NFR-P-02).
- A failed job marks `error`, exposes **Thử lại**; failure of one scene never stops others (NFR-R-01).
- On success, result Blob persisted to `assets` (Dexie) then job `done` (FR-GP-06).
- Cancel: dequeue if queued; `abort()` fetch if running.
- Blocks enqueue when the stage has no valid provider → surface config warning (FR-MC-02).

## Acceptance criteria
- Enqueue 3 jobs → they run strictly in order; UI progress updates live.
- Failing job shows error + retry; the other jobs still complete.
- Cancel stops a queued/running job.

## Notes
- UI must never block (NFR-P-01): all AI work is async/off the main interaction path.
