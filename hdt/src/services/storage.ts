import { db } from '@/lib/db'
import type {
  Asset,
  CanvasLayout,
  Character,
  Project,
  ProjectType,
  Scene,
  Script,
} from '@/types/entities'

/**
 * Pure async persistence service over Dexie (no React).
 * Feature `fetchers.ts` call these helpers instead of Axios.
 * Auto-save (NFR-R-02) is realized by callers writing on every change,
 * so every write here is intentionally cheap.
 */

// ── Shared helpers ───────────────────────────────────────────────────────────

/** Generate a collision-resistant id (uuid where available). */
export function newId(): string {
  return globalThis.crypto?.randomUUID?.() ?? `id_${Date.now()}_${Math.random().toString(36).slice(2)}`
}

const nowIso = (): string => new Date().toISOString()

/** Create an object URL for a blob. Caller is responsible for revocation. */
export function objectUrlFor(blob: Blob): string {
  return URL.createObjectURL(blob)
}

// ── projects ─────────────────────────────────────────────────────────────────

export interface CreateProjectInput {
  name: string
  type: ProjectType
  language?: string
}

export const projectsStore = {
  async create(input: CreateProjectInput): Promise<Project> {
    const ts = nowIso()
    const project: Project = {
      id: newId(),
      name: input.name,
      type: input.type,
      language: input.language ?? 'vi',
      created_at: ts,
      updated_at: ts,
    }
    await db.projects.add(project)
    return project
  },

  get(id: string): Promise<Project | undefined> {
    return db.projects.get(id)
  },

  /** Most-recently-updated first. */
  list(): Promise<Project[]> {
    return db.projects.orderBy('updated_at').reverse().toArray()
  },

  async rename(id: string, name: string): Promise<void> {
    await db.projects.update(id, { name, updated_at: nowIso() })
  },

  /** Delete a project and all of its child records. */
  async remove(id: string): Promise<void> {
    await db.transaction(
      'rw',
      [db.projects, db.scripts, db.scenes, db.assets, db.characters, db.layouts],
      async () => {
        const sceneIds = await db.scenes.where('project_id').equals(id).primaryKeys()
        await db.assets.bulkDelete(sceneIds)
        await db.scenes.where('project_id').equals(id).delete()
        await db.scripts.delete(id)
        await db.characters.where('project_id').equals(id).delete()
        await db.layouts.delete(id)
        await db.projects.delete(id)
      },
    )
  },
}

// ── scripts (one per project) ────────────────────────────────────────────────

export const scriptsStore = {
  getByProject(projectId: string): Promise<Script | undefined> {
    return db.scripts.get(projectId)
  },

  async upsert(script: Script): Promise<Script> {
    const next: Script = { ...script, updated_at: nowIso() }
    await db.scripts.put(next)
    return next
  },
}

// ── scenes ───────────────────────────────────────────────────────────────────

export const scenesStore = {
  /** Scenes for a project, sorted ascending by `order`. */
  listByProject(projectId: string): Promise<Scene[]> {
    return db.scenes.where('project_id').equals(projectId).sortBy('order')
  },

  get(id: string): Promise<Scene | undefined> {
    return db.scenes.get(id)
  },

  async upsert(scene: Scene): Promise<Scene> {
    await db.scenes.put(scene)
    return scene
  },

  /** Delete a scene and its asset row. */
  async remove(id: string): Promise<void> {
    await db.transaction('rw', [db.scenes, db.assets], async () => {
      await db.assets.delete(id)
      await db.scenes.delete(id)
    })
  },

  /** Persist a new ordering; `order` becomes the index within `orderedIds`. */
  async reorder(orderedIds: string[]): Promise<void> {
    await db.transaction('rw', db.scenes, async () => {
      await Promise.all(orderedIds.map((id, index) => db.scenes.update(id, { order: index })))
    })
  },
}

// ── assets (one per scene) ───────────────────────────────────────────────────

export const assetsStore = {
  getByScene(sceneId: string): Promise<Asset | undefined> {
    return db.assets.get(sceneId)
  },

  async upsert(asset: Asset): Promise<Asset> {
    await db.assets.put(asset)
    return asset
  },

  /** Cheap partial update — e.g. flipping a single status during the pipeline. */
  async patch(sceneId: string, changes: Partial<Asset>): Promise<void> {
    await db.assets.update(sceneId, changes)
  },
}

// ── characters (optional) ────────────────────────────────────────────────────

export const charactersStore = {
  listByProject(projectId: string): Promise<Character[]> {
    return db.characters.where('project_id').equals(projectId).toArray()
  },

  async upsert(character: Character): Promise<Character> {
    await db.characters.put(character)
    return character
  },

  remove(id: string): Promise<void> {
    return db.characters.delete(id)
  },
}

// ── layouts (React Flow storyboard canvas, one per project) ──────────────────

export const layoutsStore = {
  getByProject(projectId: string): Promise<CanvasLayout | undefined> {
    return db.layouts.get(projectId)
  },

  async upsert(layout: CanvasLayout): Promise<CanvasLayout> {
    await db.layouts.put(layout)
    return layout
  },
}
