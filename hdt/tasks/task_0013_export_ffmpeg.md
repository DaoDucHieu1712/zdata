# task_0013 — Video export (ffmpeg.wasm)

**Priority:** P1  **Depends on:** 0011, 0012  **FRs:** FR-EX-01..04, SRD §7.2

## Goal
Client-side assembly of scenes into a single MP4 using `@ffmpeg/ffmpeg`, downloadable, with resolution/fps options.

## Scope
- Add deps `@ffmpeg/ffmpeg`, `@ffmpeg/util` (needs approval).
- `src/services/exporter.ts` — `export(projectId, { resolution, fps })` (SRD §7.2):
  1. Load scenes by derived `order` (task_0008).
  2. `image` mode → `ffmpeg -loop 1 -i image -t duration_sec` → segment; `video` mode → use `video_blob` (normalize fps/resolution).
  3. Mix per-scene voice audio; mix BGM at lower volume (task_0012).
  4. `concat` segments → `final.mp4`.
  5. Return Blob for download.
- `src/features/export/components/export-modal.tsx` — options + progress + download (`uiStore.exportOpen`).

## Requirements
- **FR-EX-01/02:** ordered concat, image→video conversion, audio mix; client-side ffmpeg.wasm; MP4 download.
- **FR-EX-03 (P2):** resolution 720p/1080p, fps 24/30 selectable.
- **FR-EX-04 (P3):** export a single scene (per-clip) to avoid browser memory limits on long videos.

## Acceptance criteria
- Mixed image+video project exports to one playable MP4 with audio.
- Resolution/fps options honored.
- Progress shown during export; per-scene export works.

## Notes
- ffmpeg.wasm needs WASM support and cross-origin isolation headers if using multithread build — configure Next headers accordingly. Watch memory on long exports (FR-EX-04 mitigates).
