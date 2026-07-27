import Dexie, { type Table } from 'dexie'
import type {
  Asset,
  CanvasLayout,
  Character,
  Project,
  Scene,
  Script,
} from '@/types/entities'

/**
 * Client-side persistence for all project data (IndexedDB via Dexie).
 * Schema is intentionally flat — each object store maps 1:1 to a future
 * relational table if server sync is ever added (out of scope for v0.1).
 *
 * Cloud AI provider config + pipeline graph live in localStorage, NOT here,
 * and are never part of a project export (SRD §4.6).
 */
export class HdtDatabase extends Dexie {
  projects!: Table<Project, string>
  scripts!: Table<Script, string>
  scenes!: Table<Scene, string>
  assets!: Table<Asset, string>
  characters!: Table<Character, string>
  layouts!: Table<CanvasLayout, string>

  constructor() {
    super('hdt')
    this.version(1).stores({
      projects: 'id, type, updated_at',
      scripts: 'project_id',
      scenes: 'id, project_id, order',
      assets: 'scene_id',
      characters: 'id, project_id',
      layouts: 'project_id',
    })
  }
}

export const db = new HdtDatabase()
