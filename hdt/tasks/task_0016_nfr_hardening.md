# task_0016 — NFR hardening & i18n (vi)

**Priority:** P2  **Depends on:** most feature tasks  **FRs:** NFR-P-01/02, NFR-R-01/02, NFR-S-01/02, NFR-U-01, NFR-C-01

## Goal
Cross-cutting quality pass to meet non-functional requirements.

## Scope / checklist
- **NFR-P-01:** UI interactions (add/edit scene, open panel) respond < 200ms; AI work off the interaction path (verify no sync blocking).
- **NFR-P-02:** job progress reflects on UI without reload (already via callbacks — verify end-to-end).
- **NFR-R-01:** all Cloud AI failures show a clear error + retry; one scene's failure never blocks others.
- **NFR-R-02:** autosave after every change (scenes, script, layout, providers) — audit each mutation writes to Dexie/localStorage.
- **NFR-S-01:** API keys never logged, never shown in full, never in exports — grep/audit.
- **NFR-S-02:** reject non-`https://` endpoints everywhere (schema + adapter guard).
- **NFR-U-01:** Vietnamese default copy; centralize strings (simple `vi` dictionary) — no hardcoded English in UI.
- **NFR-C-01:** deployable as static SPA — verify `next build` output works on a static host (or documented adapter); no server-only dependencies leak in.

## Acceptance criteria
- A written checklist verified item-by-item with evidence (screenshots/logs).
- `npm run lint` + `tsc` clean across the codebase.
- Manual smoke test of the full flow: idea → script → scenes → image/video → voice → export.

## Notes
- Toast errors via `react-toastify` (already a dependency).
