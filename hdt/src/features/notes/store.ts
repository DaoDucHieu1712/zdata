import { create } from 'zustand'

interface NotesUIState {
  expandedFolders: Set<string>
  showTrash: boolean
  renamingId: string | null

  toggleFolder:   (id: string) => void
  expandFolder:   (id: string) => void
  collapseFolder: (id: string) => void
  setShowTrash:   (show: boolean) => void
  setRenaming:    (id: string | null) => void
}

export const useNotesStore = create<NotesUIState>((set) => ({
  expandedFolders: new Set<string>(),
  showTrash: false,
  renamingId: null,

  toggleFolder: (id) =>
    set((s) => {
      const next = new Set(s.expandedFolders)
      if (next.has(id)) { next.delete(id) } else { next.add(id) }
      return { expandedFolders: next }
    }),

  expandFolder: (id) =>
    set((s) => ({ expandedFolders: new Set([...s.expandedFolders, id]) })),

  collapseFolder: (id) =>
    set((s) => {
      const next = new Set(s.expandedFolders)
      next.delete(id)
      return { expandedFolders: next }
    }),

  setShowTrash: (showTrash) => set({ showTrash }),
  setRenaming:  (renamingId) => set({ renamingId }),
}))
