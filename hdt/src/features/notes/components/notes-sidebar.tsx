'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { cn } from '@/lib/utils/cn'
import { useFolderTree, useNotesList, useTrash } from '../api/queries'
import { useCreateNote, useDeleteNote, useCreateFolder, useRestoreNote, useRestoreFolder } from '../api/mutations'
import { fetchNotes } from '../api/fetchers'
import { useNotesStore } from '../store'
import { FolderTreeNode } from './folder-tree-node'
import { ROUTES } from '@/config/routes'
import type { NoteResponseDto } from '../types/notes.types'
import Link from 'next/link'
import { usePathname } from 'next/navigation'

function ApiErrorBanner({ message }: { message: string }) {
  return (
    <div className="mx-2 mt-1 rounded px-2 py-1 text-[11px] text-[#d13438] bg-[#fde7e9]">
      {message}
    </div>
  )
}

// ── Root note leaf ──────────────────────────────────────────────────────────────

function RootNoteItem({ note }: { note: NoteResponseDto }) {
  const pathname = usePathname()
  const isActive = pathname === ROUTES.NOTE(note.id)
  const [showMenu, setShowMenu] = useState(false)
  const deleteNote = useDeleteNote()

  return (
    <div className="relative">
      <Link
        href={ROUTES.NOTE(note.id)}
        className={cn(
          'group flex items-center gap-1.5 rounded px-3 py-[3px] text-[13px] transition-colors',
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
        <div className="absolute right-1 top-7 z-50 w-36 rounded-lg border border-[#e8e8e5] bg-white py-1 shadow-xl">
          <button
            type="button"
            onClick={() => { setShowMenu(false); deleteNote.mutate(note.id) }}
            className="flex w-full items-center gap-2 px-3 py-1.5 text-[13px] text-[#d13438] hover:bg-[#fff0f0]"
          >
            Move to Trash
          </button>
        </div>
      )}
    </div>
  )
}

// ── Trash section ──────────────────────────────────────────────────────────────

function TrashSection() {
  const { showTrash, setShowTrash } = useNotesStore()
  const { data: trash } = useTrash(showTrash)
  const restoreNote   = useRestoreNote()
  const restoreFolder = useRestoreFolder()

  const isEmpty = !trash?.notes.length && !trash?.folders.length

  return (
    <div className="border-t border-[#e9e8e5] pt-2">
      <button
        type="button"
        onClick={() => setShowTrash(!showTrash)}
        className="flex w-full items-center gap-2 rounded px-3 py-1.5 text-[12px] text-[#9b9a97] hover:bg-[#e9e8e5] hover:text-[#37352f]"
      >
        <span>🗑</span>
        <span>Trash</span>
        <svg className={cn('ml-auto h-3 w-3 transition-transform', showTrash && 'rotate-90')}
          fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
        </svg>
      </button>

      {showTrash && (
        <div className="px-1 pb-2">
          {isEmpty ? (
            <p className="px-3 py-2 text-[12px] text-[#c1bfbc]">Trash is empty</p>
          ) : (
            <>
              {trash?.folders.map((f) => (
                <div key={f.id} className="flex items-center gap-2 rounded px-3 py-1">
                  <span className="text-[12px] text-[#9b9a97] flex-1 truncate">📁 {f.name}</span>
                  <button
                    type="button"
                    onClick={() => restoreFolder.mutate(f.id)}
                    className="text-[11px] text-[#0078d4] hover:underline shrink-0"
                  >
                    Restore
                  </button>
                </div>
              ))}
              {trash?.notes.map((n) => (
                <div key={n.id} className="flex items-center gap-2 rounded px-3 py-1">
                  <span className="text-[12px] text-[#9b9a97] flex-1 truncate">📄 {n.title ?? 'Untitled'}</span>
                  <button
                    type="button"
                    onClick={() => restoreNote.mutate(n.id)}
                    className="text-[11px] text-[#0078d4] hover:underline shrink-0"
                  >
                    Restore
                  </button>
                </div>
              ))}
            </>
          )}
        </div>
      )}
    </div>
  )
}

// ── Main sidebar ────────────────────────────────────────────────────────────────

export function NotesSidebar() {
  const router = useRouter()
  const { data: tree = [] }    = useFolderTree()
  const { data: rootNotes }    = useNotesList({ pageSize: 100 })
  const createNote             = useCreateNote()
  const createFolder           = useCreateFolder()
  const deleteNote             = useDeleteNote()
  const [newPageError, setNewPageError] = useState<string | null>(null)
  const [creatingPage, setCreatingPage] = useState(false)

  const handleNewPage = async () => {
    setNewPageError(null)
    setCreatingPage(true)
    try {
      const before = Date.now()
      await createNote.mutateAsync({ title: 'Untitled' })
      const notes = await fetchNotes({ pageSize: 50 })
      const newest = notes.items.find((n) => n.createdAt && new Date(n.createdAt).getTime() >= before)
        ?? notes.items[0]
      if (newest) router.push(ROUTES.NOTE(newest.id))
    } catch {
      setNewPageError('Could not create page.')
    } finally {
      setCreatingPage(false)
    }
  }

  const handleNewFolder = () => {
    createFolder.mutate({ name: 'New Folder', parentId: null })
  }

  const handleDeleteNote = (id: string) => {
    deleteNote.mutate(id)
  }

  return (
    <aside className="flex w-[240px] shrink-0 flex-col overflow-hidden border-r border-[#e9e8e5] bg-[#f7f6f3]">
      {/* Header */}
      <div className="flex items-center justify-between px-3 pt-3 pb-1">
        <span className="text-[13px] font-semibold text-[#37352f]">Notes</span>
        <div className="flex items-center gap-1">
          <button
            type="button"
            onClick={handleNewFolder}
            title="New folder"
            className="flex h-6 w-6 items-center justify-center rounded text-[#9b9a97] hover:bg-[#e9e8e5] hover:text-[#37352f]"
          >
            <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 10.5v6m3-3H9m4.06-7.19-2.12-2.12a1.5 1.5 0 0 0-1.061-.44H4.5A2.25 2.25 0 0 0 2.25 6v12a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9a2.25 2.25 0 0 0-2.25-2.25h-5.379a1.5 1.5 0 0 1-1.06-.44Z" />
            </svg>
          </button>
          <button
            type="button"
            onClick={handleNewPage}
            disabled={creatingPage}
            title="New page"
            className="flex h-6 w-6 items-center justify-center rounded text-[#9b9a97] hover:bg-[#e9e8e5] hover:text-[#37352f] text-[16px] leading-none disabled:opacity-40"
          >
            {creatingPage ? '…' : '+'}
          </button>
        </div>
      </div>

      {/* Tree — scrollable */}
      <div className="flex-1 overflow-y-auto px-1 pb-1">
        {newPageError && <ApiErrorBanner message={newPageError} />}
        {/* Root-level notes */}
        {(rootNotes?.items ?? []).map((note) => (
          <RootNoteItem key={note.id} note={note} />
        ))}

        {/* Folder tree */}
        {tree.map((folder) => (
          <FolderTreeNode
            key={folder.id}
            folder={folder}
            depth={0}
            onDeleteNote={handleDeleteNote}
          />
        ))}

        {/* Empty hint */}
        {tree.length === 0 && !rootNotes?.items.length && (
          <button
            type="button"
            onClick={handleNewPage}
            className="mx-2 mt-2 flex items-center gap-1.5 rounded px-2 py-1.5 text-[12px] text-[#9b9a97] hover:bg-[#e9e8e5] hover:text-[#37352f] w-full"
          >
            <span>+</span>
            <span>Add a page</span>
          </button>
        )}
      </div>

      {/* Trash */}
      <TrashSection />
    </aside>
  )
}
