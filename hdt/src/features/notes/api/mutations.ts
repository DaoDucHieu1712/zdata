import { useMutation, useQueryClient } from '@tanstack/react-query'
import {
  createFolder, updateFolder, deleteFolder, moveFolder, restoreFolder,
  createNote, updateNote, deleteNote, moveNote, restoreNote,
} from './fetchers'
import { NOTES_KEYS } from './queries'

const useQC = () => useQueryClient()

export const useCreateFolder = () => {
  const qc = useQC()
  return useMutation({
    mutationFn: createFolder,
    onSuccess: () => qc.invalidateQueries({ queryKey: NOTES_KEYS.tree }),
  })
}

export const useUpdateFolder = () => {
  const qc = useQC()
  return useMutation({
    mutationFn: updateFolder,
    onSuccess: () => qc.invalidateQueries({ queryKey: NOTES_KEYS.tree }),
  })
}

export const useDeleteFolder = () => {
  const qc = useQC()
  return useMutation({
    mutationFn: deleteFolder,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: NOTES_KEYS.tree })
      qc.invalidateQueries({ queryKey: NOTES_KEYS.trash })
    },
  })
}

export const useMoveFolder = () => {
  const qc = useQC()
  return useMutation({
    mutationFn: moveFolder,
    onSuccess: () => qc.invalidateQueries({ queryKey: NOTES_KEYS.tree }),
  })
}

export const useRestoreFolder = () => {
  const qc = useQC()
  return useMutation({
    mutationFn: restoreFolder,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: NOTES_KEYS.tree })
      qc.invalidateQueries({ queryKey: NOTES_KEYS.trash })
    },
  })
}

export const useCreateNote = () => {
  const qc = useQC()
  return useMutation({
    mutationFn: createNote,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['notes', 'list'] })
    },
  })
}

export const useUpdateNote = () => {
  const qc = useQC()
  return useMutation({
    mutationFn: updateNote,
    onSuccess: (_, vars) => {
      qc.invalidateQueries({ queryKey: NOTES_KEYS.note(vars.id) })
    },
  })
}

export const useDeleteNote = () => {
  const qc = useQC()
  return useMutation({
    mutationFn: deleteNote,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['notes', 'list'] })
      qc.invalidateQueries({ queryKey: NOTES_KEYS.trash })
    },
  })
}

export const useMoveNote = () => {
  const qc = useQC()
  return useMutation({
    mutationFn: moveNote,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notes', 'list'] }),
  })
}

export const useRestoreNote = () => {
  const qc = useQC()
  return useMutation({
    mutationFn: restoreNote,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['notes', 'list'] })
      qc.invalidateQueries({ queryKey: NOTES_KEYS.trash })
    },
  })
}
