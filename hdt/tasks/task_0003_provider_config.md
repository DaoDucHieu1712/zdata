# task_0003 — Cloud AI provider config + API key vault

**Priority:** P1  **Depends on:** 0001  **FRs:** FR-MC-01, FR-MC-04, FR-MC-06, NFR-S-01, NFR-S-02

## Goal
Declare Cloud AI providers via a form and persist them to localStorage with lightly-encrypted API keys. Foundation for the pipeline canvas (0004) and adapters (0005).

## Scope
- `src/lib/crypto.ts` — Web Crypto light encrypt/decrypt for API keys (`encryptKey`, `decryptKey`, `maskKey → sk-****1234`).
- `src/features/ai-config/`:
  ```
  types/ai-config.types.ts   # CloudProviderConfig, StageCategory='llm'|'image'|'video'|'tts',
                             #   PipelineGraph, StageSelection (SRD §4.6)
  schemas/provider.schema.ts # name, category enum, endpoint_url (must be https://), api_key, model_id
  store.ts                   # useConfigStore (zustand, persisted to localStorage):
                             #   providers[], pipelineNodes, pipelineEdges,
                             #   stageSelection (derived), actions: saveProvider/deleteProvider/getProvider
  components/provider-form.tsx
  index.ts
  ```
- Persistence rules:
  - `api_key_enc` only in localStorage; **never** in React Flow node data (SRD §4.6 note).
  - `getProvider(id)` decrypts key **only at call time**.
  - Reject non-`https://` endpoints in schema (NFR-S-02).
  - Display masked key after save; never re-show plaintext (FR-MC-04).

## Acceptance criteria
- Add/edit/delete providers of each category; survives reload.
- Stored key is encrypted (inspect localStorage — no plaintext).
- `http://` endpoint rejected with a clear validation message.
- Cloud-only: no local-AI option anywhere (FR-MC-06).

## Notes
- `stageSelection` is **derived** from `pipelineEdges`, not stored independently.
