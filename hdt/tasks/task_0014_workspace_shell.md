# task_0014 — Project workspace shell & routing

**Priority:** P1  **Depends on:** 0002  **FRs:** SRD §2.1, §5.1; NFR-U-01

## Goal
The per-project workspace that hosts the toolbar, script panel, storyboard canvas, scene editor, AI pipeline canvas, and export modal.

## Scope
- Route `src/app/projects/[projectId]/page.tsx` → `ProjectWorkspace`.
- `src/features/workspace/components/project-workspace.tsx` composing:
  - `Toolbar` — Tạo kịch bản · Tạo phân cảnh · Sinh tất cả · Xuất video · Cấu hình AI.
  - `ScriptPanel` (0007), `StoryboardCanvas` (0008), `SceneInspector` (0010),
    `AIPipelineCanvas` (0004, modal via `uiStore.aiPipelineOpen`), `ExportModal` (0013).
- Extend `src/stores/ui-store.ts`: `editorOpen`, `editorSceneId`, `aiPipelineOpen`, `exportOpen` (SRD §2.2).
- Add route constants to `src/config/routes.ts`.
- Reuse `components/common/app-shell.tsx` for layout.

## Requirements
- **NFR-U-01:** Vietnamese default UI copy throughout.
- Toolbar buttons open the right panels/canvases and dispatch the right flows.
- Layout ≥1280px optimized (SRD §2.4).

## Acceptance criteria
- Opening a project from the dashboard lands in the workspace.
- Each toolbar action opens/triggers its feature.
- UI state (which panel/modal open) is coherent and does not block the canvas.

## Notes
- Cross-feature composition happens here at the `app/`/`workspace` layer — features stay decoupled (no cross-feature imports; use barrels).
