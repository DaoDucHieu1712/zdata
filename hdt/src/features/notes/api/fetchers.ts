import { apiClient } from '@/lib/api-client'
import type { ApiResponse, PagedResult } from '@/types/api'
import type {
  FolderResponseDto,
  NoteResponseDto,
  CreateFolderPayload,
  UpdateFolderPayload,
  MoveFolderPayload,
  CreateNotePayload,
  UpdateNotePayload,
  MoveNotePayload,
  TrashedItemsResponseDto,
  NoteListParams,
} from '../types/notes.types'

// ── Folder ──────────────────────────────────────────────────────────────────────

export const fetchFolderTree = async (): Promise<FolderResponseDto[]> => {
  const { data: env } = await apiClient.get<ApiResponse<FolderResponseDto[]>>('/api/folder')
  return env.data
}

export const createFolder = async (payload: CreateFolderPayload): Promise<void> => {
  await apiClient.post('/api/folder', payload)
}

export const updateFolder = async ({ id, ...body }: UpdateFolderPayload): Promise<void> => {
  await apiClient.put(`/api/folder/${id}`, body)
}

export const deleteFolder = async (id: string): Promise<void> => {
  await apiClient.delete(`/api/folder/${id}`)
}

export const moveFolder = async ({ id, newParentId }: MoveFolderPayload): Promise<void> => {
  await apiClient.patch(`/api/folder/${id}/move`, { newParentId })
}

export const restoreFolder = async (id: string): Promise<void> => {
  await apiClient.post(`/api/folder/${id}/restore`)
}

// ── Note ────────────────────────────────────────────────────────────────────────

export const fetchNotes = async (params?: NoteListParams): Promise<PagedResult<NoteResponseDto>> => {
  const { data: env } = await apiClient.get<ApiResponse<PagedResult<NoteResponseDto>>>('/api/note', { params })
  return env.data
}

export const fetchNote = async (id: string): Promise<NoteResponseDto> => {
  const { data: env } = await apiClient.get<ApiResponse<NoteResponseDto>>(`/api/note/${id}`)
  return env.data
}

export const fetchTrash = async (): Promise<TrashedItemsResponseDto> => {
  const { data: env } = await apiClient.get<ApiResponse<TrashedItemsResponseDto>>('/api/note/trash')
  return env.data
}

export const createNote = async (payload: CreateNotePayload): Promise<void> => {
  await apiClient.post('/api/note', payload)
}

export const updateNote = async ({ id, ...body }: UpdateNotePayload): Promise<void> => {
  await apiClient.put(`/api/note/${id}`, body)
}

export const deleteNote = async (id: string): Promise<void> => {
  await apiClient.delete(`/api/note/${id}`)
}

export const moveNote = async ({ id, folderId }: MoveNotePayload): Promise<void> => {
  await apiClient.patch(`/api/note/${id}/move`, { folderId })
}

export const restoreNote = async (id: string): Promise<void> => {
  await apiClient.post(`/api/note/${id}/restore`)
}
