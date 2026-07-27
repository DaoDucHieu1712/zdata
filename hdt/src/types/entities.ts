import type { Edge, Node, Viewport } from '@xyflow/react'

// ── Enums / status unions (SRD §4) ───────────────────────────────────────────

export type ProjectType = 'film' | 'vlog' | 'video'
export type MediaMode = 'video' | 'image'
export type JobStatus = 'queued' | 'running' | 'done' | 'error'
/** Video may additionally be `skipped` (e.g. scenes in `image` mode). */
export type VideoStatus = JobStatus | 'skipped'
export type ImageSource = 'ai' | 'manual'

// ── 4.1 projects ─────────────────────────────────────────────────────────────

export interface Project {
  id: string
  name: string
  type: ProjectType
  language: string
  created_at: string
  updated_at: string
}

// ── 4.2 scripts (one per project, keyed by project_id) ───────────────────────

export interface Script {
  project_id: string
  premise: string
  tone_tags: string[]
  full_text: string
  updated_at: string
}

// ── 4.3 scenes ───────────────────────────────────────────────────────────────

export interface Scene {
  id: string
  project_id: string
  order: number
  title: string
  prompt: string
  camera_note?: string
  media_mode: MediaMode
  duration_sec: number
  dialogue?: string
  status: JobStatus
}

// ── 4.4 assets (one per scene, keyed by scene_id) ────────────────────────────

export interface Asset {
  scene_id: string
  image_blob?: Blob
  image_status: JobStatus
  image_source: ImageSource
  /** Only present in `video` media mode; `null`/absent in `image` mode. */
  video_blob?: Blob | null
  video_status: VideoStatus
  audio_blob?: Blob
  audio_status: JobStatus
}

// ── 4.5 characters (optional) ────────────────────────────────────────────────

export interface Character {
  id: string
  project_id: string
  name: string
  description: string
}

// ── layouts (React Flow storyboard canvas, keyed by project_id) ──────────────

export interface CanvasLayout {
  project_id: string
  nodes: Node[]
  edges: Edge[]
  viewport: Viewport
}
