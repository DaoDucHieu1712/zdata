'use client'

import { useRef, useState, useCallback } from 'react'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { cn } from '@/lib/utils/cn'
import { useNotesStore } from '../store'
import { useNotesList } from '../api/queries'
import { useCreateNote, useUpdateFolder, useDeleteFolder, useCreateFolder } from '../api/mutations'
import { fetchNotes } from '../api/fetchers'
import { ROUTES } from '@/config/routes'
import type { FolderResponseDto, NoteResponseDto } from '../types/notes.types'

// ── Note leaf ──────────────────────────────────────────────────────────────────

interface NoteLeafProps {
  note: NoteResponseDto
  depth: number
  onDelete: (id: string) => void
}

function NoteLeaf({ note, depth, onDelete }: NoteLeafProps) {
  const pathname = usePathname()
  const isActive = pathname === ROUTES.NOTE(note.id)
  const [showMenu, setShowMenu] = useState(false)
  const menuRef = useRef<HTMLDivElement>(null)

  return (
    <div className="relative">
      <Link
        href={ROUTES.NOTE(note.id)}
        style={{ paddingLeft: `${depth * 16 + 28}px` }}
        className={cn(
          'group flex items-center gap-1.5 rounded py-[3px] pr-2 text-[13px] transition-colors',
          isActive ? 'bg-[#e8e6e3] text-[#37352f]' : 'text-[#787774] hover:bg-[#e9e8e5] hover:text-[#37352f]',
        )}
      >
        <span className="shrink-0 text-[12px] opacity-60">📄</span>
        <span className="flex-1 truncate">{note.title ?? 'Untitled'}</span>
        <button
          type="button"
          onClick={(e) => { e.preventDefault(); e.stopPropagation(); setShowMenu((v) => !v) }}
          className="ml-auto flex h-5 w-5 shrink-0 items-center justify-center rounded text-[#9b9a97] opacity-0 transition group-hover:opacity-100 hover:bg-[#d9d8d5]"
        >
          ···
        </button>
      </Link>

      {showMenu && (
        <div
          ref={menuRef}
          className="absolute right-1 top-7 z-50 w-36 rounded-lg border border-[#e8e8e5] bg-white py-1 shadow-xl"
        >
          <button
            type="button"
            onClick={() => { onDelete(note.id); setShowMenu(false) }}
            className="flex w-full items-center gap-2 px-3 py-1.5 text-[13px] text-[#d13438] hover:bg-[#fff0f0]"
          >
            Move to Trash
          </button>
        </div>
      )}
    </div>
  )
}

// ── Folder notes (lazy) ────────────────────────────────────────────────────────

interface FolderNotesProps {
  folderId: string
  depth: number
  onDeleteNote: (id: string) => void
}

function FolderNotes({ folderId, depth, onDeleteNote }: FolderNotesProps) {
  const { data } = useNotesList({ folderId, pageSize: 100 })
  const notes = data?.items ?? []
  return (
    <>
      {notes.map((note) => (
        <NoteLeaf key={note.id} note={note} depth={depth} onDelete={onDeleteNote} />
      ))}
    </>
  )
}

// ── Folder node (recursive) ────────────────────────────────────────────────────

interface FolderTreeNodeProps {
  folder: FolderResponseDto
  depth?: number
  onDeleteNote: (id: string) => void
}

export function FolderTreeNode({ folder, depth = 0, onDeleteNote }: FolderTreeNodeProps) {
  const router = useRouter()
  const { expandedFolders, toggleFolder, renamingId, setRenaming } = useNotesStore()
  const isExpanded = expandedFolders.has(folder.id)

  const createNoteMutation  = useCreateNote()
  const updateFolderMutation = useUpdateFolder()
  const deleteFolderMutation = useDeleteFolder()
  const createFolderMutation = useCreateFolder()

  const [showMenu, setShowMenu]   = useState(false)
  const [renameVal, setRenameVal] = useState(folder.name)
  const isRenaming = renamingId === folder.id

  const handleToggle = useCallback((e: React.MouseEvent) => {
    e.stopPropagation()
    toggleFolder(folder.id)
  }, [folder.id, toggleFolder])

  const handleAddNote = useCallback(async (e: React.MouseEvent) => {
    e.stopPropagation()
    setShowMenu(false)
    try {
      const before = Date.now()
      await createNoteMutation.mutateAsync({ title: 'Untitled', folderId: folder.id })
      const notes = await fetchNotes({ folderId: folder.id, pageSize: 50 })
      const newest = notes.items.find((n) => n.createdAt && new Date(n.createdAt).getTime() >= before)
        ?? notes.items[0]
      if (newest) {
        useNotesStore.getState().expandFolder(folder.id)
        router.push(ROUTES.NOTE(newest.id))
      }
    } catch {
      // mutation error is accessible via createNoteMutation.error if needed
    }
  }, [folder.id, createNoteMutation, router])

  const handleAddFolder = useCallback(() => {
    setShowMenu(false)
    createFolderMutation.mutate(
      { name: 'New Folder', parentId: folder.id },
      { onSuccess: () => useNotesStore.getState().expandFolder(folder.id) },
    )
  }, [folder.id, createFolderMutation])

  const handleRenameSubmit = useCallback(() => {
    setRenaming(null)
    if (renameVal.trim() && renameVal !== folder.name) {
      updateFolderMutation.mutate({ id: folder.id, name: renameVal.trim() })
    }
  }, [folder.id, folder.name, renameVal, setRenaming, updateFolderMutation])

  const handleDelete = useCallback(() => {
    setShowMenu(false)
    if (confirm(`Move "${folder.name}" and all its contents to Trash?`)) {
      deleteFolderMutation.mutate(folder.id)
    }
  }, [folder.id, folder.name, deleteFolderMutation])

  return (
    <div>
      {/* Row */}
      <div
        style={{ paddingLeft: `${depth * 16 + 8}px` }}
        className="group relative flex items-center gap-0.5 rounded py-[3px] pr-1 transition-colors hover:bg-[#e9e8e5]"
      >
        {/* Expand chevron */}
        <button
          type="button"
          onClick={handleToggle}
          className="flex h-5 w-5 shrink-0 items-center justify-center rounded text-[#9b9a97] hover:bg-[#d9d8d5]"
        >
          <svg
            className={cn('h-3 w-3 transition-transform', isExpanded && 'rotate-90')}
            fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
          </svg>
        </button>

        {/* Icon */}
        <span className="text-[14px]">{folder.icon ?? '📁'}</span>

        {/* Name or rename input */}
        {isRenaming ? (
          <input
            autoFocus
            value={renameVal}
            onChange={(e) => setRenameVal(e.target.value)}
            onBlur={handleRenameSubmit}
            onKeyDown={(e) => {
              if (e.key === 'Enter') { e.preventDefault(); handleRenameSubmit() }
              if (e.key === 'Escape') { setRenaming(null); setRenameVal(folder.name) }
            }}
            className="flex-1 rounded border border-[#0078d4] bg-white px-1 text-[13px] text-[#37352f] outline-none"
            onClick={(e) => e.stopPropagation()}
          />
        ) : (
          <span
            className="flex-1 truncate text-[13px] text-[#37352f] cursor-pointer"
            onDoubleClick={() => setRenaming(folder.id)}
          >
            {folder.name}
          </span>
        )}

        {/* Hover actions */}
        <div className="ml-auto flex items-center gap-0.5 opacity-0 transition group-hover:opacity-100">
          <button
            type="button"
            onClick={handleAddNote}
            title="New page"
            className="flex h-5 w-5 items-center justify-center rounded text-[#9b9a97] hover:bg-[#d9d8d5] text-[12px]"
          >
            +
          </button>
          <button
            type="button"
            onClick={(e) => { e.stopPropagation(); setShowMenu((v) => !v) }}
            className="flex h-5 w-5 items-center justify-center rounded text-[#9b9a97] hover:bg-[#d9d8d5] text-[12px]"
          >
            ···
          </button>
        </div>

        {/* Context menu */}
        {showMenu && (
          <div className="absolute right-1 top-7 z-50 w-44 rounded-lg border border-[#e8e8e5] bg-white py-1 shadow-xl">
            <button
              type="button"
              onClick={(e) => { e.stopPropagation(); setRenaming(folder.id); setShowMenu(false) }}
              className="flex w-full items-center gap-2 px-3 py-1.5 text-[13px] text-[#37352f] hover:bg-[#f7f6f3]"
            >
              Rename
            </button>
            <button
              type="button"
              onClick={(e) => { e.stopPropagation(); handleAddNote(e) }}
              className="flex w-full items-center gap-2 px-3 py-1.5 text-[13px] text-[#37352f] hover:bg-[#f7f6f3]"
            >
              New page inside
            </button>
            <button
              type="button"
              onClick={(e) => { e.stopPropagation(); handleAddFolder() }}
              className="flex w-full items-center gap-2 px-3 py-1.5 text-[13px] text-[#37352f] hover:bg-[#f7f6f3]"
            >
              New folder inside
            </button>
            <div className="my-1 border-t border-[#e9e9e7]" />
            <button
              type="button"
              onClick={(e) => { e.stopPropagation(); handleDelete() }}
              className="flex w-full items-center gap-2 px-3 py-1.5 text-[13px] text-[#d13438] hover:bg-[#fff0f0]"
            >
              Move to Trash
            </button>
          </div>
        )}
      </div>

      {/* Children */}
      {isExpanded && (
        <div>
          {folder.children.map((child) => (
            <FolderTreeNode key={child.id} folder={child} depth={depth + 1} onDeleteNote={onDeleteNote} />
          ))}
          <FolderNotes folderId={folder.id} depth={depth + 1} onDeleteNote={onDeleteNote} />
        </div>
      )}
    </div>
  )
}
