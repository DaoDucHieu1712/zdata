import type { MediaMode } from '../types/storyboard.types'

/** SRS media_mode options offered in the scene inspector. */
export const MEDIA_MODES: { value: MediaMode; label: string }[] = [
  { value: 'video', label: '🎥 Video clip' },
  { value: 'image', label: '🖼 Static image' },
]

/** Voices exposed for TTS (FR-VA-02). Real list comes from the provider. */
export const VOICE_PRESETS = [
  { value: 'vi-female-1', label: 'Nữ (VI) — Linh' },
  { value: 'vi-male-1', label: 'Nam (VI) — Minh' },
  { value: 'en-female-1', label: 'Female (EN) — Ava' },
]

/** Clip-length limits for video mode; image mode is unbounded (SRS FR-GP-04). */
export const VIDEO_MIN_DURATION = 3
export const VIDEO_MAX_DURATION = 10

export const DEFAULT_VOICE = 'vi-female-1'
export const DEFAULT_SPEED = 1

/** Accepted manual-upload image types + size cap (SRS FR-GP-03). */
export const UPLOAD_ACCEPT = 'image/png,image/jpeg,image/webp'
export const UPLOAD_MAX_BYTES = 20 * 1024 * 1024

/** Seed values applied to a freshly-created scene. */
export const SCENE_DEFAULTS = {
  prompt: '',
  cameraNote: '',
  mediaMode: 'video' as MediaMode,
  durationSec: 5,
  dialogue: '',
}

/**
 * When true, the API fetchers fall back to a local mock generator if the real
 * endpoint at NEXT_PUBLIC_API_URL is unreachable, so the demo runs offline.
 * Set to false once a real Cloud AI backend is wired up.
 */
export const USE_MOCK_FALLBACK = true

/** localStorage key for the auto-saved canvas layout (FR-SB-02). */
export const LAYOUT_STORAGE_KEY = 'bongstudio.storyboard.layout.v1'
