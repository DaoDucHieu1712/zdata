# task_0007 — Script generation panel

**Priority:** P1  **Depends on:** 0002, 0005  **FRs:** FR-SG-01..06

## Goal
Panel to generate a raw script from an idea via Cloud LLM, edit it, and hand off to storyboard breakdown.

## Scope — `src/features/script/`
```
api/fetchers.ts   # generateScript(premise, toneTags, length) via aiClient.call('llm'); saveScript via storage
api/queries.ts    # useScript(projectId)
api/mutations.ts  # useGenerateScript (streaming), useSaveScript
schemas/script.schema.ts   # premise (required), toneTags: string[], length: 'short'|'medium'|'custom'+words
types/script.types.ts
components/script-panel.tsx   # RHF form + generated text editor (textarea/rich editor)
index.ts
```

## Requirements
- **FR-SG-01:** inputs — premise (free text, required), tone tags (vui/kịch tính/cảm động/hài…), target length (ngắn/vừa/custom word count).
- **FR-SG-02:** generate structured raw script in project language (default `vi`).
- **FR-SG-03:** result saved to `scripts` store and editable in a text editor before use.
- **FR-SG-04 (P2):** stream output progressively (use aiClient `onProgress`/chunked reads).
- **FR-SG-05:** "Tạo phân cảnh từ kịch bản" button → triggers auto-breakdown (task_0009).
- **FR-SG-06 (P3):** rewrite a selected passage with custom instruction ("làm đoạn này kịch tính hơn").

## Acceptance criteria
- Generate produces script text; long generations stream visibly.
- Edits persist (autosave to Dexie).
- Breakdown button is wired (may call the 0009 flow).

## Notes
- Reuse existing rich-text editor (`components/common/rich-text-editor.tsx`) or a plain textarea per SRD §1.3.
