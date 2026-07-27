import type { ReactNode } from 'react'
import { NotesSidebar } from '@/features/notes'

export default function NotesLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex h-full overflow-hidden">
      <NotesSidebar />
      <main className="flex flex-1 flex-col overflow-hidden bg-white">
        {children}
      </main>
    </div>
  )
}
