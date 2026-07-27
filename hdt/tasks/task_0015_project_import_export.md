# task_0015 — Project JSON import/export

**Priority:** P2  **Depends on:** 0001, 0002  **FRs:** FR-PM-04, NFR-S-01

## Goal
Back up / move a project as a JSON file (project + scenes + script), excluding API keys.

## Scope
- `src/features/projects/api/fetchers.ts` — `exportProject(projectId): Blob` and `importProject(json): Project`.
- Serialize `project + scenes + script` (+ characters, layout) to JSON; download.
- Import validates with zod and writes new records (new ids to avoid collisions).
- **NFR-S-01 / FR-PM-04:** never include `api_key` / provider config in the export.
- Note: large binary assets (image/video/audio Blobs) — decide MVP scope: metadata-only export vs base64 (document the choice; default metadata-only, regenerate assets after import). Add `TODO` if deferring binaries.

## Acceptance criteria
- Export produces a downloadable JSON with no key material anywhere.
- Import recreates the project and its scenes/script; opens in workspace.
- Round-trip export→import preserves scene fields and order.

## Notes
- Config (providers/pipeline) lives in localStorage and is intentionally excluded (SRD §4 note).
