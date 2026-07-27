# task_0012 — Voice-over (TTS) & audio

**Priority:** P1  **Depends on:** 0006, 0008  **FRs:** FR-VA-01..04

## Goal
Generate voice-over from scene dialogue via Cloud TTS, choose voice/speed, add project BGM, preview audio.

## Scope
- Scene action "Sinh giọng đọc" → `ttsAdapter` for scenes with `dialogue`; store `audio_blob`/`audio_status` in `assets`.
- **FR-VA-02:** voice + speed selectable from the provider's voice list (fetch/list per provider; fallback static list). Persist selection per scene or project default.
- **FR-VA-03 (P2):** upload one project-level **BGM** file; stored (localStorage-ref or Dexie); mixed under voice at lower volume at export time (hand-off to task_0013).
- **FR-VA-04 (P3):** in-app audio preview of a scene's generated voice before export.

## Acceptance criteria
- Scenes with dialogue produce audio; job-tracked; persisted.
- Voice + speed choices affect output and are remembered.
- BGM uploads and is available to the exporter.
- Preview plays the generated audio.

## Notes
- Runs as a Job through the queue (`gen_audio`); parallelizable after image per SRD §5.1 (still sequential in MVP).
