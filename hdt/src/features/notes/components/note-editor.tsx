'use client'

import { useCallback, useEffect, useRef, useState } from 'react'
import { cn } from '@/lib/utils/cn'
import { useNote } from '../api/queries'
import { useUpdateNote } from '../api/mutations'
import { NoteBlock } from './note-block'
import { SlashMenu } from './slash-menu'
import type { Block, BlockType } from '../types/notes.types'
import type { BlockState } from './note-block'

function genId(): string {
  return Math.random().toString(36).slice(2) + Date.now().toString(36)
}

function parseBlocks(content: string | null): { states: BlockState[]; contents: Record<string, string> } {
  if (!content) return { states: [{ id: genId(), type: 'paragraph' }], contents: {} }
  try {
    const raw: Block[] = JSON.parse(content)
    const states = raw.map((b) => ({ id: b.id, type: b.type, checked: b.checked, language: b.language }))
    const contents: Record<string, string> = {}
    raw.forEach((b) => { contents[b.id] = b.content ?? '' })
    return { states: states.length ? states : [{ id: genId(), type: 'paragraph' }], contents }
  } catch {
    return { states: [{ id: genId(), type: 'paragraph' }], contents: {} }
  }
}

interface SlashMenuState {
  blockId: string
  query: string
  rect: DOMRect
}

interface NoteEditorProps {
  noteId: string
}

export function NoteEditor({ noteId }: NoteEditorProps) {
  const { data: noteData, isLoading } = useNote(noteId)
  const updateMutation = useUpdateNote()

  const [blocks, setBlocks] = useState<BlockState[]>([{ id: genId(), type: 'paragraph' }])
  const [initContents, setInitContents] = useState<Record<string, string>>({})
  const [slashMenu, setSlashMenu] = useState<SlashMenuState | null>(null)
  const [saveStatus, setSaveStatus] = useState<'saved' | 'saving' | 'unsaved'>('saved')
  const [initialized, setInitialized] = useState(false)
  const [newBlockId, setNewBlockId] = useState<string | null>(null)

  const titleRef = useRef<HTMLDivElement>(null)
  const blockEls = useRef<Map<string, HTMLElement>>(new Map())
  const blocksRef = useRef(blocks)
  const saveTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined)

  useEffect(() => { blocksRef.current = blocks }, [blocks])

  // Initialize editor when note data loads
  useEffect(() => {
    if (!noteData || initialized) return
    if (titleRef.current) titleRef.current.textContent = noteData.title ?? ''
    const { states, contents } = parseBlocks(noteData.content)
    setBlocks(states)
    setInitContents(contents)
    setInitialized(true)
    setSaveStatus('saved')
  }, [noteData, initialized])

  // Reset when note changes
  useEffect(() => {
    setInitialized(false)
    setBlocks([{ id: genId(), type: 'paragraph' }])
    setInitContents({})
    setNewBlockId(null)
    blockEls.current.clear()
    setSaveStatus('saved')
  }, [noteId])

  const getContent = useCallback((id: string) => blockEls.current.get(id)?.textContent ?? '', [])

  const save = useCallback(async () => {
    setSaveStatus('saving')
    const blockData: Block[] = blocksRef.current.map((b) => ({
      id: b.id,
      type: b.type,
      content: getContent(b.id),
      checked: b.checked,
      language: b.language,
    }))
    try {
      await updateMutation.mutateAsync({
        id: noteId,
        title: titleRef.current?.textContent ?? '',
        content: JSON.stringify(blockData),
      })
      setSaveStatus('saved')
    } catch {
      setSaveStatus('unsaved')
    }
  }, [noteId, getContent, updateMutation])

  const triggerSave = useCallback(() => {
    setSaveStatus('unsaved')
    clearTimeout(saveTimer.current)
    saveTimer.current = setTimeout(save, 800)
  }, [save])

  // ── Block manipulation ─────────────────────────────────────────────────────

  const insertBlockAfter = useCallback((afterId: string, type: BlockType = 'paragraph') => {
    const id = genId()
    setBlocks((prev) => {
      const idx = prev.findIndex((b) => b.id === afterId)
      const next = [...prev]
      next.splice(idx + 1, 0, { id, type })
      return next
    })
    setNewBlockId(id)
    return id
  }, [])

  const deleteBlock = useCallback((id: string) => {
    setBlocks((prev) => {
      if (prev.length <= 1) return prev
      const idx = prev.findIndex((b) => b.id === id)
      const next = prev.filter((b) => b.id !== id)
      // Focus previous block after deletion
      const prevBlock = prev[idx - 1]
      if (prevBlock) {
        setTimeout(() => {
          const el = blockEls.current.get(prevBlock.id)
          if (el) {
            el.focus()
            const range = document.createRange()
            const sel = window.getSelection()
            range.selectNodeContents(el)
            range.collapse(false)
            sel?.removeAllRanges()
            sel?.addRange(range)
          }
        }, 0)
      }
      return next
    })
    blockEls.current.delete(id)
    triggerSave()
  }, [triggerSave])

  // ── Event handlers ──────────────────────────────────────────────────────────

  const handleRef = useCallback((id: string, el: HTMLElement | null) => {
    if (el) blockEls.current.set(id, el)
    else blockEls.current.delete(id)
  }, [])

  const handleInput = useCallback((blockId: string) => {
    const el = blockEls.current.get(blockId)
    const text = el?.textContent ?? ''

    if (text === '/') {
      const rect = el!.getBoundingClientRect()
      setSlashMenu({ blockId, query: '', rect })
    } else if (text.startsWith('/') && slashMenu?.blockId === blockId) {
      const rect = el!.getBoundingClientRect()
      setSlashMenu({ blockId, query: text.slice(1), rect })
    } else {
      setSlashMenu(null)
    }
    triggerSave()
  }, [slashMenu, triggerSave])

  const handleKeyDown = useCallback((blockId: string, e: React.KeyboardEvent) => {
    const el = blockEls.current.get(blockId)
    const text = el?.textContent ?? ''
    const block = blocksRef.current.find((b) => b.id === blockId)

    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      setSlashMenu(null)
      // Inherit list type for list items, else create paragraph
      const newType: BlockType =
        block?.type === 'bulletList' ? 'bulletList' :
        block?.type === 'numberedList' ? 'numberedList' :
        block?.type === 'todo' ? 'todo' :
        'paragraph'
      insertBlockAfter(blockId, newType)
      triggerSave()
      return
    }

    if (e.key === 'Backspace' && text === '') {
      e.preventDefault()
      setSlashMenu(null)
      deleteBlock(blockId)
      return
    }

    if (e.key === 'Escape') {
      setSlashMenu(null)
    }
  }, [insertBlockAfter, deleteBlock, triggerSave])

  const handleSlashSelect = useCallback((type: BlockType) => {
    if (!slashMenu) return
    const el = blockEls.current.get(slashMenu.blockId)
    if (el) el.textContent = ''
    setBlocks((prev) => prev.map((b) => b.id === slashMenu.blockId ? { ...b, type } : b))
    setSlashMenu(null)
    setTimeout(() => blockEls.current.get(slashMenu.blockId)?.focus(), 0)
    triggerSave()
  }, [slashMenu, triggerSave])

  const handleCheck = useCallback((blockId: string, checked: boolean) => {
    setBlocks((prev) => prev.map((b) => b.id === blockId ? { ...b, checked } : b))
    triggerSave()
  }, [triggerSave])

  // Compute list numbers
  let listCounter = 0
  const blockNumbers: Record<string, number> = {}
  blocks.forEach((b, i) => {
    if (b.type === 'numberedList') {
      listCounter = (i > 0 && blocks[i - 1].type === 'numberedList') ? listCounter + 1 : 1
      blockNumbers[b.id] = listCounter
    } else {
      listCounter = 0
    }
  })

  if (isLoading) {
    return (
      <div className="flex flex-1 items-center justify-center text-[#c1bfbc]">
        <svg className="h-6 w-6 animate-spin" fill="none" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
        </svg>
      </div>
    )
  }

  return (
    <div className="flex h-full flex-col overflow-hidden">
      {/* Save status */}
      <div className="flex shrink-0 items-center justify-end px-10 py-2">
        <span className={cn('text-[11px] transition-colors',
          saveStatus === 'saving'  ? 'text-[#0078d4]' :
          saveStatus === 'unsaved' ? 'text-[#d13438]' :
          'text-[#c1bfbc]'
        )}>
          {saveStatus === 'saving' ? 'Saving…' : saveStatus === 'unsaved' ? 'Unsaved' : 'Saved'}
        </span>
      </div>

      {/* Scrollable content */}
      <div className="flex-1 overflow-y-auto px-10 pb-32">
        <div className="mx-auto max-w-[720px] pt-16">
          {/* Title */}
          <div
            ref={titleRef}
            contentEditable
            suppressContentEditableWarning
            data-placeholder="Untitled"
            onInput={triggerSave}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault()
                blockEls.current.get(blocks[0]?.id)?.focus()
              }
            }}
            className={cn(
              'mb-4 w-full text-[2.5rem] font-bold leading-tight text-[#37352f] outline-none',
              'empty:before:content-[attr(data-placeholder)] empty:before:text-[#c1bfbc] empty:before:pointer-events-none',
            )}
          />

          {/* Blocks */}
          <div className="flex flex-col gap-[2px]">
            {blocks.map((block) => (
              <div key={block.id} className="group relative flex items-start gap-1 py-[1px]">
                {/* Drag handle (visual only) */}
                <span className="mt-[5px] shrink-0 cursor-grab select-none text-[#c1bfbc] opacity-0 transition-opacity group-hover:opacity-100">
                  ⠿
                </span>
                <div className="min-w-0 flex-1">
                  <NoteBlock
                    block={block}
                    initialContent={initContents[block.id] ?? ''}
                    listNumber={blockNumbers[block.id]}
                    onRef={handleRef}
                    onInput={handleInput}
                    onKeyDown={handleKeyDown}
                    onCheck={handleCheck}
                    autoFocus={block.id === newBlockId}
                  />
                </div>
              </div>
            ))}
          </div>

          {/* Click area below blocks to add new block */}
          <div
            className="mt-2 h-16 cursor-text"
            onClick={() => {
              const last = blocks[blocks.length - 1]
              const el = last && blockEls.current.get(last.id)
              if (el) el.focus()
              else insertBlockAfter(blocks[blocks.length - 1]?.id ?? '')
            }}
          />
        </div>
      </div>

      {/* Slash command menu */}
      {slashMenu && (
        <SlashMenu
          query={slashMenu.query}
          anchorRect={slashMenu.rect}
          onSelect={handleSlashSelect}
          onClose={() => setSlashMenu(null)}
        />
      )}
    </div>
  )
}
