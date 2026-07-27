export type BlockType =
  | 'heading1' | 'heading2' | 'heading3'
  | 'paragraph'
  | 'bulletList' | 'numberedList'
  | 'todo'
  | 'divider'
  | 'code'

export interface Block {
  id: string
  type: BlockType
  content?: string
  checked?: boolean
  language?: string
}

export interface FolderResponseDto {
  id: string
  name: string
  parentId: string | null
  icon: string | null
  createdAt: string | null
  updatedAt: string | null
  children: FolderResponseDto[]
}

export interface NoteResponseDto {
  id: string
  title: string | null
  content: string | null
  folderId: string | null
  createdAt: string | null
  updatedAt: string | null
}

export interface CreateFolderPayload {
  name: string
  parentId?: string | null
  icon?: string | null
}

export interface UpdateFolderPayload {
  id: string
  name?: string | null
  icon?: string | null
}

export interface MoveFolderPayload {
  id: string
  newParentId: string | null
}

export interface CreateNotePayload {
  title?: string | null
  content?: string | null
  folderId?: string
}

export interface UpdateNotePayload {
  id: string
  title?: string | null
  content?: string | null
}

export interface MoveNotePayload {
  id: string
  folderId: string | null
}

export interface TrashedFolderDto {
  id: string
  name: string
  parentId: string | null
  updatedAt: string | null
}

export interface TrashedNoteDto {
  id: string
  title: string | null
  folderId: string | null
  updatedAt: string | null
}

export interface TrashedItemsResponseDto {
  folders: TrashedFolderDto[]
  notes: TrashedNoteDto[]
}

export interface NoteListParams {
  folderId?: string
  search?: string
  pageIndex?: number
  pageSize?: number
}
