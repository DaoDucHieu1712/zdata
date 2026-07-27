import type { Node, Edge } from '@xyflow/react'

/** Node kinds on the storyboard canvas. A scene is the core "storyboard" node. */
export type StoryboardNodeKind = 'scene' | 'render'

/** SRS media_mode — a scene is either a motion clip or a held still frame. */
export type MediaMode = 'video' | 'image'

/** SRS scene lifecycle status. `idle` is the pre-run state. */
export type SceneStatus = 'idle' | 'queued' | 'running' | 'done' | 'error'

/** Per-asset status. `skipped` applies to video for image-mode scenes. */
export type AssetStatus = 'idle' | 'queued' | 'running' | 'done' | 'error' | 'skipped'

/** SRS asset image_source — AI-generated vs. manually uploaded. */
export type ImageSource = 'ai' | 'manual'

/**
 * Data carried by a storyboard scene node (SRS §4.3 scenes + §4.4 assets).
 * Blob columns from the SRS are represented as object/data URLs to fit the
 * repo's axios + TanStack Query stack instead of IndexedDB.
 */
export interface SceneNodeData extends Record<string, unknown> {
  kind: 'scene'
  /** 1-based order for display + export; derived from the edge chain (FR-SB-02b). */
  order: number
  title: string
  /** Image description that drives text-to-image (SRS prompt). */
  prompt: string
  /** Optional camera-movement note used for image-to-video (SRS camera_note). */
  cameraNote: string
  mediaMode: MediaMode
  durationSec: number
  /** Optional dialogue / narration used for TTS (SRS dialogue). */
  dialogue: string
  status: SceneStatus

  imageUrl: string | null
  imageStatus: AssetStatus
  imageSource: ImageSource

  videoUrl: string | null
  videoStatus: AssetStatus

  audioUrl: string | null
  audioStatus: AssetStatus

  /** Progress (0–1) of the currently running job on this scene (SRD §2.3). */
  progress: number
  error: string | null
}

/** Data carried by the terminal render node that stitches scene clips. */
export interface RenderNodeData extends Record<string, unknown> {
  kind: 'render'
  status: AssetStatus
  videoUrl: string | null
  transition: 'none' | 'fade' | 'slide'
  error: string | null
}

export type StoryboardNodeData = SceneNodeData | RenderNodeData

export type SceneNode = Node<SceneNodeData, 'scene'>
export type RenderNode = Node<RenderNodeData, 'render'>
export type StoryboardNode = Node<StoryboardNodeData>
export type StoryboardEdge = Edge

// ── AI generation API contracts ────────────────────────────────

export interface GenerateImageRequest {
  prompt: string
  cameraNote?: string
}
export interface GenerateImageResponse {
  imageUrl: string
  width: number
  height: number
}

export interface GenerateVideoRequest {
  imageUrl: string
  prompt: string
  durationSec: number
  cameraNote?: string
}
export interface GenerateVideoResponse {
  videoUrl: string
  durationSec: number
}

/** Cloud TTS (FR-VA-01/02). */
export interface GenerateAudioRequest {
  text: string
  voice: string
  speed: number
}
export interface GenerateAudioResponse {
  audioUrl: string
  durationSec: number
}

/** One clip fed to the final stitch. */
export interface RenderClip {
  mediaMode: MediaMode
  imageUrl: string | null
  videoUrl: string | null
  audioUrl: string | null
  durationSec: number
}
export interface RenderVideoRequest {
  clips: RenderClip[]
  transition: RenderNodeData['transition']
}
export interface RenderVideoResponse {
  videoUrl: string
  durationSec: number
}

/** Auto scene-breakdown from a script (FR-SB-04). */
export interface BreakdownScene {
  title: string
  prompt: string
  durationSec: number
  dialogue?: string
  cameraNote?: string
}
export interface AutoBreakdownRequest {
  scriptText: string
  projectType?: 'film' | 'vlog' | 'video'
}
export interface AutoBreakdownResponse {
  scenes: BreakdownScene[]
}
