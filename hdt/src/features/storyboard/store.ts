import { create } from 'zustand'
import {
  addEdge,
  applyEdgeChanges,
  applyNodeChanges,
  type Connection,
  type EdgeChange,
  type NodeChange,
  type Viewport,
  type XYPosition,
} from '@xyflow/react'
import { autoBreakdown, generateAudio, generateImage, generateVideo, renderVideo } from './api/fetchers'
import {
  DEFAULT_SPEED,
  DEFAULT_VOICE,
  LAYOUT_STORAGE_KEY,
  SCENE_DEFAULTS,
  UPLOAD_ACCEPT,
  UPLOAD_MAX_BYTES,
  VIDEO_MAX_DURATION,
  VIDEO_MIN_DURATION,
} from './config/storyboard-config'
import type {
  BreakdownScene,
  RenderClip,
  RenderNode,
  SceneNode,
  SceneNodeData,
  StoryboardEdge,
  StoryboardNode,
} from './types/storyboard.types'

let seq = 0
const nextId = (p: string) => `${p}-${Date.now().toString(36)}-${++seq}`

const SCENE_W = 300
const DEFAULT_VIEWPORT: Viewport = { x: 0, y: 0, zoom: 1 }

function makeScene(order: number, position: XYPosition, patch: Partial<SceneNodeData> = {}): SceneNode {
  return {
    id: nextId('scene'),
    type: 'scene',
    position,
    data: {
      kind: 'scene',
      order,
      title: `Scene ${order}`,
      prompt: SCENE_DEFAULTS.prompt,
      cameraNote: SCENE_DEFAULTS.cameraNote,
      mediaMode: SCENE_DEFAULTS.mediaMode,
      durationSec: SCENE_DEFAULTS.durationSec,
      dialogue: SCENE_DEFAULTS.dialogue,
      status: 'idle',
      imageUrl: null,
      imageStatus: 'idle',
      imageSource: 'ai',
      videoUrl: null,
      videoStatus: 'idle',
      audioUrl: null,
      audioStatus: 'idle',
      progress: 0,
      error: null,
      ...patch,
    },
  }
}

function seed(): { nodes: StoryboardNode[]; edges: StoryboardEdge[] } {
  const s1 = makeScene(1, { x: 40, y: 80 }, {
    prompt: 'Wide shot of a neon city at dusk, rain-slicked streets',
    dialogue: 'The city never really sleeps.',
  })
  const s2 = makeScene(2, { x: 380, y: 80 }, {
    prompt: 'Close-up of a lone traveler looking up at the skyline',
    cameraNote: 'slow push-in',
  })
  const render: RenderNode = {
    id: nextId('render'),
    type: 'render',
    position: { x: 720, y: 120 },
    data: { kind: 'render', status: 'idle', videoUrl: null, transition: 'fade', error: null },
  }
  return {
    nodes: [s1, s2, render],
    edges: [
      { id: `${s1.id}->${s2.id}`, source: s1.id, target: s2.id, animated: true },
      { id: `${s2.id}->${render.id}`, source: s2.id, target: render.id, animated: true },
    ],
  }
}

/** Type guard narrowing a node to a scene node. */
const isScene = (n: StoryboardNode): n is SceneNode => n.data.kind === 'scene'

/**
 * Resolve export order from the transition-edge chain (FR-SB-02b). Follows
 * scene→scene edges from the head (a scene with no incoming scene edge); any
 * scenes not reached fall back to creation order.
 */
function deriveOrder(nodes: StoryboardNode[], edges: StoryboardEdge[]): SceneNode[] {
  const scenes = nodes.filter(isScene)
  if (scenes.length <= 1) return [...scenes]

  const sceneIds = new Set(scenes.map((s) => s.id))
  const sceneEdges = edges.filter((e) => sceneIds.has(e.source) && sceneIds.has(e.target))
  if (sceneEdges.length === 0) return [...scenes]

  const nextOf = new Map<string, string>()
  for (const e of sceneEdges) if (!nextOf.has(e.source)) nextOf.set(e.source, e.target)
  const targets = new Set(sceneEdges.map((e) => e.target))
  const head = scenes.find((s) => !targets.has(s.id)) ?? scenes[0]

  const ordered: SceneNode[] = []
  const seen = new Set<string>()
  let cur: string | undefined = head.id
  while (cur && !seen.has(cur)) {
    seen.add(cur)
    const node = scenes.find((s) => s.id === cur)
    if (node) ordered.push(node)
    cur = nextOf.get(cur)
  }
  for (const s of scenes) if (!seen.has(s.id)) ordered.push(s) // disconnected scenes
  return ordered
}

/** Stamp each scene's `order` field from the derived export order. */
function renumber(nodes: StoryboardNode[], edges: StoryboardEdge[]): StoryboardNode[] {
  const orderById = new Map(deriveOrder(nodes, edges).map((n, i) => [n.id, i + 1]))
  return nodes.map((n) =>
    isScene(n) ? { ...n, data: { ...n.data, order: orderById.get(n.id) ?? n.data.order } } : n,
  )
}

// ── layout persistence (FR-SB-02) ──────────────────────────────

interface StoredLayout {
  nodes: StoryboardNode[]
  edges: StoryboardEdge[]
  viewport: Viewport
}

function loadLayout(): StoredLayout | null {
  if (typeof window === 'undefined') return null
  try {
    const raw = window.localStorage.getItem(LAYOUT_STORAGE_KEY)
    return raw ? (JSON.parse(raw) as StoredLayout) : null
  } catch {
    return null
  }
}

let saveTimer: ReturnType<typeof setTimeout> | null = null
function persist(get: GetFn) {
  if (typeof window === 'undefined') return
  if (saveTimer) clearTimeout(saveTimer)
  saveTimer = setTimeout(() => {
    const { nodes, edges, viewport } = get()
    try {
      window.localStorage.setItem(LAYOUT_STORAGE_KEY, JSON.stringify({ nodes, edges, viewport }))
    } catch {
      // Quota exceeded or serialization error — non-fatal for the demo.
    }
  }, 400)
}

interface StoryboardState {
  nodes: StoryboardNode[]
  edges: StoryboardEdge[]
  viewport: Viewport
  selectedId: string | null
  isBusy: boolean
  hydrated: boolean

  onNodesChange: (c: NodeChange<StoryboardNode>[]) => void
  onEdgesChange: (c: EdgeChange<StoryboardEdge>[]) => void
  onConnect: (c: Connection) => void
  setViewport: (v: Viewport) => void
  saveLayout: () => void
  hydrate: () => void
  resetBoard: () => void

  addScene: () => void
  removeNode: (id: string) => void
  selectNode: (id: string | null) => void
  updateScene: (id: string, patch: Partial<SceneNodeData>) => void
  addScenesFromBreakdown: (scenes: BreakdownScene[]) => void
  breakdownFromScript: (scriptText: string, projectType?: 'film' | 'vlog' | 'video') => Promise<void>

  uploadSceneImage: (id: string, file: File) => Promise<void>
  generateSceneImage: (id: string) => Promise<void>
  generateSceneVideo: (id: string) => Promise<void>
  generateSceneAudio: (id: string) => Promise<void>
  generateScene: (id: string) => Promise<void>
  generateAll: () => Promise<void>
  renderFinal: () => Promise<void>
}

// Always seed deterministically for SSR; real layout is loaded via hydrate().
const initial = seed()

export const useStoryboardStore = create<StoryboardState>((set, get) => ({
  nodes: initial.nodes,
  edges: initial.edges,
  viewport: DEFAULT_VIEWPORT,
  selectedId: null,
  isBusy: false,
  hydrated: false,

  onNodesChange: (c) => {
    set((s) => ({ nodes: applyNodeChanges(c, s.nodes) }))
    if (c.some((ch) => ch.type === 'position' || ch.type === 'remove')) persist(get)
  },
  onEdgesChange: (c) => {
    set((s) => {
      const edges = applyEdgeChanges(c, s.edges)
      return { edges, nodes: renumber(s.nodes, edges) }
    })
    persist(get)
  },
  onConnect: (c) =>
    set((s) => {
      const edges = addEdge({ ...c, animated: true }, s.edges)
      persist(get)
      return { edges, nodes: renumber(s.nodes, edges) }
    }),

  setViewport: (viewport) => {
    set({ viewport })
    persist(get)
  },
  saveLayout: () => persist(get),

  hydrate: () => {
    if (get().hydrated) return
    const stored = loadLayout()
    if (stored?.nodes?.length) {
      set({
        nodes: stored.nodes,
        edges: stored.edges ?? [],
        viewport: stored.viewport ?? DEFAULT_VIEWPORT,
        hydrated: true,
      })
    } else {
      set({ hydrated: true })
    }
  },

  resetBoard: () => {
    const fresh = seed()
    set({ nodes: fresh.nodes, edges: fresh.edges, viewport: DEFAULT_VIEWPORT, selectedId: null })
    persist(get)
  },

  addScene: () => {
    const scenes = get().nodes.filter(isScene)
    const last = scenes[scenes.length - 1]
    const position: XYPosition = last
      ? { x: last.position.x + SCENE_W + 40, y: last.position.y }
      : { x: 40, y: 80 }
    const node = makeScene(scenes.length + 1, position)
    set((s) => ({ nodes: renumber([...s.nodes, node], s.edges), selectedId: node.id }))
    persist(get)
  },

  removeNode: (id) => {
    set((s) => {
      const nodes = s.nodes.filter((n) => n.id !== id)
      const edges = s.edges.filter((e) => e.source !== id && e.target !== id)
      return {
        nodes: renumber(nodes, edges),
        edges,
        selectedId: s.selectedId === id ? null : s.selectedId,
      }
    })
    persist(get)
  },

  selectNode: (selectedId) => set({ selectedId }),

  updateScene: (id, patch) => {
    set((s) => ({
      nodes: s.nodes.map((n) =>
        n.id === id && isScene(n) ? { ...n, data: { ...n.data, ...patch } } : n,
      ),
    }))
    persist(get)
  },

  addScenesFromBreakdown: (scenes) => {
    set((s) => {
      const existing = s.nodes.filter(isScene).length
      const baseY = 80
      const newNodes = scenes.map((sc, i) =>
        makeScene(existing + i + 1, { x: 40 + (existing + i) * (SCENE_W + 40), y: baseY }, {
          title: sc.title || `Scene ${existing + i + 1}`,
          prompt: sc.prompt,
          durationSec: sc.durationSec || SCENE_DEFAULTS.durationSec,
          dialogue: sc.dialogue ?? '',
          cameraNote: sc.cameraNote ?? '',
        }),
      )
      const nodes = [...s.nodes, ...newNodes]
      return { nodes: renumber(nodes, s.edges) }
    })
    persist(get)
  },

  breakdownFromScript: async (scriptText, projectType) => {
    if (!scriptText.trim()) return
    const res = await autoBreakdown({ scriptText, projectType })
    const valid = res.scenes.filter((s) => s.prompt && s.prompt.trim().length > 0)
    get().addScenesFromBreakdown(valid)
  },

  uploadSceneImage: async (id, file) => {
    const node = get().nodes.find((n) => n.id === id)
    if (!node || !isScene(node)) return
    if (!UPLOAD_ACCEPT.split(',').includes(file.type)) {
      get().updateScene(id, { imageStatus: 'error', error: 'Unsupported image type (PNG/JPEG/WebP)' })
      return
    }
    if (file.size > UPLOAD_MAX_BYTES) {
      get().updateScene(id, { imageStatus: 'error', error: 'Image exceeds 20 MB' })
      return
    }
    const dataUrl = await fileToDataUrl(file)
    get().updateScene(id, {
      imageUrl: dataUrl,
      imageStatus: 'done',
      imageSource: 'manual',
      error: null,
    })
  },

  generateSceneImage: async (id) => {
    const node = get().nodes.find((n) => n.id === id)
    if (!node || !isScene(node)) return
    get().updateScene(id, { imageStatus: 'running', status: 'running', progress: 0.2, error: null })
    try {
      const res = await generateImage({ prompt: node.data.prompt, cameraNote: node.data.cameraNote })
      get().updateScene(id, {
        imageStatus: 'done',
        imageSource: 'ai',
        imageUrl: res.imageUrl,
        progress: 0.5,
      })
    } catch (e) {
      get().updateScene(id, { imageStatus: 'error', status: 'error', progress: 0, error: errMsg(e) })
    }
  },

  generateSceneVideo: async (id) => {
    const node = get().nodes.find((n) => n.id === id)
    if (!node || !isScene(node)) return
    if (node.data.mediaMode === 'image') {
      get().updateScene(id, { videoStatus: 'skipped' })
      return
    }
    if (!node.data.imageUrl) return
    const durationSec = clampVideoDuration(node.data.durationSec)
    get().updateScene(id, { videoStatus: 'running', status: 'running', progress: 0.6, error: null })
    try {
      const res = await generateVideo({
        imageUrl: node.data.imageUrl,
        prompt: node.data.prompt,
        durationSec,
        cameraNote: node.data.cameraNote,
      })
      get().updateScene(id, { videoStatus: 'done', videoUrl: res.videoUrl, progress: 0.9 })
    } catch (e) {
      get().updateScene(id, { videoStatus: 'error', status: 'error', progress: 0, error: errMsg(e) })
    }
  },

  generateSceneAudio: async (id) => {
    const node = get().nodes.find((n) => n.id === id)
    if (!node || !isScene(node) || !node.data.dialogue.trim()) return
    get().updateScene(id, { audioStatus: 'running', error: null })
    try {
      const res = await generateAudio({
        text: node.data.dialogue,
        voice: DEFAULT_VOICE,
        speed: DEFAULT_SPEED,
      })
      get().updateScene(id, { audioStatus: 'done', audioUrl: res.audioUrl })
    } catch (e) {
      get().updateScene(id, { audioStatus: 'error', error: errMsg(e) })
    }
  },

  generateScene: async (id) => {
    get().updateScene(id, { status: 'running', error: null })
    await get().generateSceneImage(id)
    const afterImage = get().nodes.find((n) => n.id === id)
    if (!afterImage || !isScene(afterImage) || afterImage.data.imageStatus !== 'done') return

    if (afterImage.data.mediaMode === 'video') {
      await get().generateSceneVideo(id)
    } else {
      get().updateScene(id, { videoStatus: 'skipped' })
    }
    if (afterImage.data.dialogue.trim()) await get().generateSceneAudio(id)

    // Finalize scene status from the resulting asset statuses.
    const done = get().nodes.find((n) => n.id === id)
    if (done && isScene(done)) {
      const failed =
        done.data.imageStatus === 'error' ||
        done.data.videoStatus === 'error' ||
        done.data.audioStatus === 'error'
      get().updateScene(id, { status: failed ? 'error' : 'done', progress: failed ? 0 : 1 })
    }
  },

  generateAll: async () => {
    if (get().isBusy) return
    set({ isBusy: true })
    try {
      for (const scene of deriveOrder(get().nodes, get().edges)) {
        if (scene.data.status === 'done') continue // FR-GP-08: only unfinished scenes
        await get().generateScene(scene.id)
      }
    } finally {
      set({ isBusy: false })
    }
  },

  renderFinal: async () => {
    const render = get().nodes.find((n) => n.data.kind === 'render')
    if (!render) return
    const clips: RenderClip[] = deriveOrder(get().nodes, get().edges)
      .filter((n) => (n.data.mediaMode === 'video' ? n.data.videoUrl : n.data.imageUrl))
      .map((n) => ({
        mediaMode: n.data.mediaMode,
        imageUrl: n.data.imageUrl,
        videoUrl: n.data.videoUrl,
        audioUrl: n.data.audioUrl,
        durationSec: n.data.durationSec,
      }))

    if (clips.length === 0) {
      setRenderData(set, render.id, { status: 'error', error: 'Generate scene media first' })
      return
    }
    setRenderData(set, render.id, { status: 'running', error: null })
    try {
      const res = await renderVideo({ clips, transition: getTransition(get, render.id) })
      setRenderData(set, render.id, { status: 'done', videoUrl: res.videoUrl })
    } catch (e) {
      setRenderData(set, render.id, { status: 'error', error: errMsg(e) })
    }
    persist(get)
  },
}))

// ── helpers ────────────────────────────────────────────────────

type SetFn = (fn: (s: StoryboardState) => Partial<StoryboardState>) => void
type GetFn = () => StoryboardState

function setRenderData(set: SetFn, id: string, patch: Partial<RenderNode['data']>) {
  set((s) => ({
    nodes: s.nodes.map((n) =>
      n.id === id && n.data.kind === 'render' ? { ...n, data: { ...n.data, ...patch } } : n,
    ),
  }))
}

function getTransition(get: GetFn, id: string): RenderNode['data']['transition'] {
  const node = get().nodes.find((n) => n.id === id)
  return node && node.data.kind === 'render' ? node.data.transition : 'fade'
}

function clampVideoDuration(sec: number): number {
  return Math.min(VIDEO_MAX_DURATION, Math.max(VIDEO_MIN_DURATION, sec))
}

function fileToDataUrl(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result as string)
    reader.onerror = () => reject(reader.error ?? new Error('File read failed'))
    reader.readAsDataURL(file)
  })
}

function errMsg(e: unknown): string {
  return e instanceof Error ? e.message : 'Generation failed'
}
