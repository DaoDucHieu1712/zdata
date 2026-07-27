'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useCreateNote } from '../api/mutations'
import { fetchNotes } from '../api/fetchers'
import { ROUTES } from '@/config/routes'

export function NoteEmpty() {
  const router = useRouter()
  const createNote = useCreateNote()
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const handleCreate = async () => {
    setError(null)
    setLoading(true)
    try {
      const before = Date.now()
      await createNote.mutateAsync({ title: 'Untitled' })
      const notes = await fetchNotes({ pageSize: 50 })
      const newest = notes.items.find((n) => n.createdAt && new Date(n.createdAt).getTime() >= before)
        ?? notes.items[0]
      if (newest) router.push(ROUTES.NOTE(newest.id))
    } catch {
      setError('Could not create page. Make sure the Notes API is running.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex h-full flex-col items-center justify-center gap-5 text-center">
      <div className="text-5xl select-none">📝</div>
      <div>
        <p className="text-lg font-semibold text-[#37352f]">No page open</p>
        <p className="mt-1 text-[14px] text-[#9b9a97]">Select a page from the sidebar or create a new one.</p>
      </div>
      {error && (
        <p className="rounded-md bg-[#fde7e9] px-4 py-2 text-[13px] text-[#d13438] max-w-sm">{error}</p>
      )}
      <button
        type="button"
        onClick={handleCreate}
        disabled={loading}
        className="rounded-lg bg-[#37352f] px-5 py-2.5 text-[13px] font-medium text-white transition-colors hover:bg-[#1f1f1d] disabled:opacity-50"
      >
        {loading ? 'Creating…' : '+ New page'}
      </button>
    </div>
  )
}
