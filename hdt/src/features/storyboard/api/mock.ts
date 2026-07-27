import type {
  AutoBreakdownResponse,
  BreakdownScene,
  GenerateAudioResponse,
  GenerateImageResponse,
  GenerateVideoResponse,
  RenderClip,
  RenderVideoResponse,
} from '../types/storyboard.types'

/**
 * Local, dependency-free stand-ins for the Cloud AI backend so the demo runs
 * with no server. Generators return self-contained `data:` URIs — no network.
 * Swap `USE_MOCK_FALLBACK` off in storyboard-config once a real API is wired.
 */

const IMG = { w: 640, h: 360 }

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms))

/** Deterministic hue from a string so repeated prompts look stable. */
function hueFromString(s: string): number {
  let h = 0
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) % 360
  return h
}

function svgDataUri(svg: string): string {
  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`
}

function escapeXml(s: string): string {
  return s.replace(/[<>&'"]/g, (c) =>
    ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', "'": '&apos;', '"': '&quot;' }[c] ?? c),
  )
}

export async function mockGenerateImage(prompt: string): Promise<GenerateImageResponse> {
  await sleep(900)
  const { w, h } = IMG
  const hue = hueFromString(prompt)
  const label = escapeXml(prompt.slice(0, 60) || 'scene')
  const svg = `
<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="hsl(${hue} 70% 55%)"/>
      <stop offset="1" stop-color="hsl(${(hue + 60) % 360} 70% 35%)"/>
    </linearGradient>
  </defs>
  <rect width="100%" height="100%" fill="url(#g)"/>
  <circle cx="${w * 0.72}" cy="${h * 0.3}" r="${h * 0.14}" fill="hsl(${(hue + 180) % 360} 80% 75%)" opacity="0.55"/>
  <text x="20" y="${h - 24}" fill="#fff" font-family="sans-serif" font-size="16" font-weight="700">${label}</text>
</svg>`.trim()
  return { imageUrl: svgDataUri(svg), width: w, height: h }
}

export async function mockGenerateVideo(
  imageUrl: string,
  durationSec: number,
): Promise<GenerateVideoResponse> {
  await sleep(1200)
  // No real encoder in the mock: reuse the poster frame as the "clip" source.
  return { videoUrl: imageUrl, durationSec }
}

/** Silent WAV of the requested length, so downstream stitching has a real audio URL. */
export async function mockGenerateAudio(
  text: string,
  speed: number,
): Promise<GenerateAudioResponse> {
  await sleep(700)
  // ~0.4s of reading per word, scaled by speed; clamped to a sane range.
  const words = text.trim().split(/\s+/).filter(Boolean).length
  const durationSec = Math.min(60, Math.max(1, Math.round((words * 0.4) / (speed || 1))))
  return { audioUrl: silentWavDataUri(durationSec), durationSec }
}

export async function mockAutoBreakdown(
  scriptText: string,
  projectType: 'film' | 'vlog' | 'video' = 'video',
): Promise<AutoBreakdownResponse> {
  await sleep(1000)
  // Split the script into sentence-ish chunks; each becomes a scene.
  const chunks = scriptText
    .split(/(?<=[.!?。！？])\s+|\n+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0)
    .slice(0, 12)

  const scenes: BreakdownScene[] = (chunks.length ? chunks : [scriptText.trim()]).map(
    (chunk, i) => ({
      title: `Scene ${i + 1}`,
      prompt: chunk.slice(0, 160),
      durationSec: 5,
      // vlog → single narrator narration; otherwise treat the line as dialogue (FR-SB-05).
      dialogue: projectType === 'vlog' ? chunk : chunk.length < 120 ? chunk : '',
    }),
  )
  return { scenes }
}

export async function mockRenderVideo(clips: RenderClip[]): Promise<RenderVideoResponse> {
  await sleep(1400)
  const durationSec = clips.reduce((sum, c) => sum + c.durationSec, 0)
  // Return the first available frame/clip as the "final" poster for the demo.
  const first = clips.find((c) => c.videoUrl || c.imageUrl)
  return { videoUrl: first?.videoUrl ?? first?.imageUrl ?? '', durationSec }
}

// ── helpers ────────────────────────────────────────────────────

/** Build a minimal silent 8kHz mono WAV as a data URI (no deps). */
function silentWavDataUri(durationSec: number): string {
  const sampleRate = 8000
  const numSamples = sampleRate * durationSec
  const dataSize = numSamples // 8-bit mono → 1 byte/sample
  const buffer = new Uint8Array(44 + dataSize)
  const view = new DataView(buffer.buffer)
  const writeStr = (offset: number, s: string) => {
    for (let i = 0; i < s.length; i++) view.setUint8(offset + i, s.charCodeAt(i))
  }
  writeStr(0, 'RIFF')
  view.setUint32(4, 36 + dataSize, true)
  writeStr(8, 'WAVE')
  writeStr(12, 'fmt ')
  view.setUint32(16, 16, true) // PCM chunk size
  view.setUint16(20, 1, true) // PCM
  view.setUint16(22, 1, true) // mono
  view.setUint32(24, sampleRate, true)
  view.setUint32(28, sampleRate, true) // byte rate
  view.setUint16(32, 1, true) // block align
  view.setUint16(34, 8, true) // bits/sample
  writeStr(36, 'data')
  view.setUint32(40, dataSize, true)
  buffer.fill(128, 44) // 8-bit silence is 128
  let bin = ''
  for (let i = 0; i < buffer.length; i++) bin += String.fromCharCode(buffer[i])
  const base64 = typeof btoa !== 'undefined' ? btoa(bin) : Buffer.from(buffer).toString('base64')
  return `data:audio/wav;base64,${base64}`
}
