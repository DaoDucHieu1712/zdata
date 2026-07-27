# task_0010 — Scene editor panel

**Priority:** P1  **Depends on:** 0008  **FRs:** FR-SB-03

## Goal
A side panel to edit a selected scene's fields, opened from a storyboard node.

## Scope — `src/features/storyboard/components/scene-inspector.tsx` (exists — complete it)
- RHF + `scene.schema.ts` form for: `title`, `duration_sec`, `prompt`, `camera_note`, `media_mode` (radio video/image), `dialogue`.
- `media_mode` toggle behavior (mirror FR-GP-04):
  - `video`: `duration_sec` constrained to video-model limit (hint 3–10s).
  - `image`: `duration_sec` free (default 8), no video generation.
- Open/close via `uiStore.editorOpen` + `editorSceneId` (SRD §2.2).
- Autosave on change → scenes store (Dexie).

## Acceptance criteria
- Selecting a node opens the panel populated with that scene.
- Editing any field persists and updates the node preview/meta live.
- Switching `media_mode` adjusts duration rules and hides/shows video controls.

## Notes
- Reuse `components/ui/*` inputs; grid layout with `cn()`.
