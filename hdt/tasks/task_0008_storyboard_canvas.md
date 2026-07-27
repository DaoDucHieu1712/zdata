# task_0008 — Storyboard canvas (scenes on React Flow)

**Priority:** P1  **Depends on:** 0002  **FRs:** FR-SB-01, FR-SB-02, FR-SB-02b, FR-SB-03

## Goal
A React Flow canvas where each scene is a node and edges express scene-transition order. Evolve the existing `features/storyboard/*` scaffold to match SRD §2.3.

## Scope — `src/features/storyboard/`
Align/extend existing files:
```
components/storyboard-canvas.tsx  # React Flow: add/remove nodes, drag, connect/disconnect edges
components/scene-node.tsx         # StoryboardNode per SRD §2.3:
                                  #   Header (order#, title, media_mode badge 🎥/🖼, status badge)
                                  #   Preview (image/video or placeholder + duration badge)
                                  #   Meta (short prompt, first 2 dialogue lines)
                                  #   Progress bar (when job running)
                                  #   Handles (source/target)
                                  #   Actions (state-dependent — see SRD §2.3)
components/transition-edge.tsx    # ordering edges
store.ts                          # scenes CRUD + canvas nodes/edges/viewport; layout autosave
api/*                             # fetchers → storage (scenes, layouts)
schemas/scene.schema.ts           # title, duration_sec, prompt, camera_note?, media_mode, dialogue?, status
types/storyboard.types.ts         # Scene, media_mode='video'|'image'
```

## Requirements
- **FR-SB-01/03:** each scene has `title, duration_sec, prompt, camera_note?, media_mode, dialogue?, status`.
- **FR-SB-02:** add/remove/edit scenes; drag nodes; connect/disconnect edges; node positions + viewport **autosaved** (debounced `onNodeDragStop → saveLayout()`) to `layouts` store.
- **FR-SB-02b:** export/merge `order` is **derived from the edge chain**; fall back to creation order when no edges.
- Scene action buttons dispatch to generation jobs (cross-ref 0011/0012) based on asset state.

## Acceptance criteria
- Create/drag/connect scenes; layout survives reload.
- Order recomputed from edge chain; correct when edges rearranged.
- Node reflects live job progress and status badges.

## Notes
- Keep `api_key`/config out of node data. Node holds scene metadata only.
