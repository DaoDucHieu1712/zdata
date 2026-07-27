import { useQuery } from '@tanstack/react-query'
import { fetchFolderTree, fetchNote, fetchNotes, fetchTrash } from './fetchers'
import type { NoteListParams } from '../types/notes.types'

export const NOTES_KEYS = {
  tree:  ['notes', 'tree'] as const,
  notes: (params?: NoteListParams) => ['notes', 'list', params] as const,
  note:  (id: string) => ['notes', 'detail', id] as const,
  trash: ['notes', 'trash'] as const,
}

export const useFolderTree = () =>
  useQuery({ queryKey: NOTES_KEYS.tree, queryFn: fetchFolderTree })

export const useNotesList = (params?: NoteListParams) =>
  useQuery({
    queryKey: NOTES_KEYS.notes(params),
    queryFn: () => fetchNotes(params),
  })

export const useNote = (id: string | null) =>
  useQuery({
    queryKey: NOTES_KEYS.note(id ?? ''),
    queryFn: () => fetchNote(id!),
    enabled: !!id,
  })

export const useTrash = (enabled = false) =>
  useQuery({
    queryKey: NOTES_KEYS.trash,
    queryFn: fetchTrash,
    enabled,
  })
