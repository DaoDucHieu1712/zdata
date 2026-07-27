# task_0009 — Auto scene breakdown + simple characters

**Priority:** P1  **Depends on:** 0007, 0008  **FRs:** FR-SB-04, FR-SB-05, FR-SB-06

## Goal
Turn a script into a list of scenes via Cloud LLM (JSON), validate, and insert into the storyboard.

## Scope
- `src/features/script/api/fetchers.ts` (or storyboard) — `autoBreakdown(scriptText, projectType)`:
  - Call `aiClient.call('llm', …)` with a system prompt requiring a **JSON array of scenes**: `{ title, prompt, duration_sec, dialogue }`.
  - Parse + validate with zod; **drop scenes missing `prompt`**; assign incrementing `order`; insert into `scenes` (Dexie).
- **FR-SB-05 (P2):** for `vlog` projects, apply a "single narrator + narration" template (narration per scene instead of multi-character dialogue).
- **FR-SB-06 (P3):** `src/features/storyboard/` (or `characters`) — simple characters (`name` + `description`) reusable in scene prompts for visual consistency; UI to add/list and inject description into prompts.

## Acceptance criteria
- Breakdown of a sample script yields valid scenes on the canvas with sequential `order`.
- Malformed/incomplete LLM items are skipped without crashing.
- `vlog` type produces narrator-style narration.
- Character description, when set, is merged into the image prompt.

## Notes
- Validate defensively — LLM JSON can be dirty. Normalize before insert.
