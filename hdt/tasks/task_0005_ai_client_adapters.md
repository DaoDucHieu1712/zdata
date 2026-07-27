# task_0005 — aiClient entrypoint + stage adapters

**Priority:** P1  **Depends on:** 0003  **FRs:** SRD §3.1, §3.2, §5; supports FR-SG/FR-GP/FR-VA

## Goal
One provider-agnostic entrypoint `aiClient.call(stage, payload, opts)` with per-stage adapters that translate to/from each provider's format.

## Scope — `src/services/`
```
aiClient.ts            # call(stage, payload, opts): resolves provider from stageSelection,
                       #   decrypts key, dispatches to ADAPTERS[stage].run(...)
adapters/llmAdapter.ts   # text in → text out (supports streaming)
adapters/imageAdapter.ts # prompt(+character desc) → image Blob
adapters/videoAdapter.ts # image_blob(+camera_note) i2v, fallback prompt t2v; clamp duration to model limit
adapters/ttsAdapter.ts   # dialogue + voice/speed → audio Blob
errors.ts              # normalize provider errors → { code, message }; ConfigError
```
`CallOpts`: `{ onProgress?(p:number, step?:string): void; signal?: AbortSignal }`.

## Behavior (SRD §3.1)
```ts
type Stage = 'llm'|'image'|'video'|'tts'
async function call(stage, payload, opts) {
  const providerId = configStore.stageSelection[stage]
  if (!providerId) throw new ConfigError(`Chưa cấu hình Cloud AI cho công đoạn: ${stage}`)
  const provider = configStore.getProvider(providerId)   // decrypt at call time
  return ADAPTERS[stage].run(provider, payload, opts)     // normalize + fetch HTTPS
}
```
- Streaming providers (SSE/chunked): read incrementally, push `onProgress`; non-streaming: progress via status (`queued→running→done`).
- Every adapter returns `Blob` (image/video/audio) or `string` (text), and normalizes errors to `{code,message}` (SRD §5.3).
- Duration clamped to provider/model limit for video (FR-GP-04).

## Acceptance criteria
- Missing stage provider → `ConfigError` with the exact vi message.
- Each adapter has a documented request/response mapping and a mockable fetch.
- Abort via `signal` cancels the fetch where the provider supports it.

## Notes
- Adapters must not import React. Keep provider-specific quirks isolated per adapter file.
- Provide a mock adapter set for local dev (align with `features/storyboard/api/mock.ts`).
