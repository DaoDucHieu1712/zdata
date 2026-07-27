'use client'

import { use } from 'react'
import { NoteEditor } from '@/features/notes'

interface Props {
  params: Promise<{ noteId: string }>
}

export default function NotePage({ params }: Props) {
  const { noteId } = use(params)
  return <NoteEditor noteId={noteId} />
}
