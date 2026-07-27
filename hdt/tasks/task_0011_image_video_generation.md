# task_0011 — Image & video generation

**Priority:** P1  **Depends on:** 0006, 0008  **FRs:** FR-GP-01..08

## Goal
Per-scene image then video generation via Cloud AI, manual image upload, regen, and "generate all".

## Scope
Wire scene-node actions (task_0008) to `jobQueue` (task_0006) + adapters (task_0005). Persist results to `assets` (Dexie).

## Requirements
- **FR-GP-01:** "Sinh hình ảnh" → `imageAdapter` (text-to-image) from scene `prompt` (+character desc).
- **FR-GP-02:** after `image_status=done`, "Sinh video" → `videoAdapter` (i2v from image_blob + camera_note; fallback t2v from prompt).
- **FR-GP-03:** manual image upload (PNG/JPEG/WebP, ≤ 20 MB) replacing AI image; then video from it. Set `image_source='manual'`.
- **FR-GP-04:** honor `media_mode` — `image` mode skips video (`video_status='skipped'`); `video` mode clamps duration to model limit.
- **FR-GP-05:** every call tracked as a Job (`queued→running→done|error`) with progress + error.
- **FR-GP-06:** results downloaded to `assets` (IndexedDB); displayed via object URL as soon as done.
- **FR-GP-07 (P2):** regen image or video; new result replaces old.
- **FR-GP-08 (P2):** "Sinh tất cả" enqueues all incomplete scenes; show overall progress.

## Acceptance criteria
- Full flow: generate image → generate video → preview both, persisted across reload.
- Upload path (≤20MB, allowed types) works and feeds video.
- Regen replaces the previous asset. "Generate all" runs sequentially with aggregate progress.
- File-size / type validation enforced with clear errors.

## Notes
- Block generate for a stage with no valid provider (FR-MC-02) — reuse queue guard.
