# task_0004 — AI pipeline canvas (React Flow node-graph)

**Priority:** P1  **Depends on:** 0003  **FRs:** FR-MC-02, FR-MC-03, FR-MC-05, FR-MC-07

## Goal
Visual node-graph to bind each stage (LLM/Image/Video/TTS) to a provider by dragging edges. Basis: adapt existing `features/workflow/*`.

## Scope — `src/features/ai-config/components/`
```
ai-pipeline-canvas.tsx   # React Flow canvas
stage-node.tsx           # 4 nodes: LLM · Image · Video · TTS (single target handle each)
provider-node.tsx        # per provider: name, category, endpoint, model_id, masked key,
                         #   "Kiểm tra kết nối" button, status light
routing-edge.tsx         # StageNode → ProviderNode binding
```
Store actions (extend `ai-config/store.ts`): `onConnectRouting`, `testProvider`, `savePipelineLayout`.

## Rules (SRD §2.4, FR-MC-03)
- Connect allowed only when `stage.category === provider.category`; wrong category → reject, show temporary **red edge** + error toast.
- Each StageNode keeps **exactly one** routing edge; a new connection replaces the old.
- `stageSelection` recomputed from `pipelineEdges` on every graph change.
- `testProvider` pings endpoint+key → node turns **green (OK)** / **red (error)** (FR-MC-05).
- FR-MC-07 (P3): multiple providers per category; re-wire to switch quickly.
- FR-MC-02: if a stage has no valid provider, downstream generate actions are blocked with a config warning (enforced in job queue / generate buttons — cross-ref 0006/0011).

## Persistence
- Node positions + edges saved to localStorage via config store (PipelineGraph, SRD §4.6).
- **Never** put `api_key`/`api_key_enc` into node `data`.

## Acceptance criteria
- Drag LLM→(llm provider) binds; wrong-category drag rejected with red edge + toast.
- Re-wiring a stage replaces its previous edge.
- "Test connection" flips node color per result.
- Reload restores graph layout and bindings.

## Route
- Open as a modal/panel (`uiStore.aiPipelineOpen`) or `/ai-config`.
