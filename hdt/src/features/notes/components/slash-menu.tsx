'use client'

import { useEffect, useRef, useState } from 'react'
import { cn } from '@/lib/utils/cn'
import type { BlockType } from '../types/notes.types'

interface SlashCommand {
  type: BlockType
  label: string
  description: string
  icon: string
}

const COMMANDS: SlashCommand[] = [
  { type: 'paragraph',     label: 'Text',           description: 'Plain paragraph',     icon: 'T'  },
  { type: 'heading1',      label: 'Heading 1',      description: 'Big section heading', icon: 'H1' },
  { type: 'heading2',      label: 'Heading 2',      description: 'Medium heading',      icon: 'H2' },
  { type: 'heading3',      label: 'Heading 3',      description: 'Small heading',       icon: 'H3' },
  { type: 'bulletList',    label: 'Bulleted list',  description: 'Unordered list',      icon: '•'  },
  { type: 'numberedList',  label: 'Numbered list',  description: 'Ordered list',        icon: '1.' },
  { type: 'todo',          label: 'To-do',          description: 'Checkbox task',       icon: '☐'  },
  { type: 'code',          label: 'Code',           description: 'Code block',          icon: '</>' },
  { type: 'divider',       label: 'Divider',        description: 'Horizontal rule',     icon: '—'  },
]

interface SlashMenuProps {
  query: string
  onSelect: (type: BlockType) => void
  onClose: () => void
  anchorRect: DOMRect | null
}

export function SlashMenu({ query, onSelect, onClose, anchorRect }: SlashMenuProps) {
  const [activeIndex, setActiveIndex] = useState(0)
  const listRef = useRef<HTMLDivElement>(null)

  const filtered = COMMANDS.filter(
    (c) =>
      !query ||
      c.label.toLowerCase().includes(query.toLowerCase()) ||
      c.description.toLowerCase().includes(query.toLowerCase()),
  )

  useEffect(() => { setActiveIndex(0) }, [query])

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'ArrowDown') {
        e.preventDefault()
        setActiveIndex((i) => Math.min(i + 1, filtered.length - 1))
      } else if (e.key === 'ArrowUp') {
        e.preventDefault()
        setActiveIndex((i) => Math.max(i - 1, 0))
      } else if (e.key === 'Enter') {
        e.preventDefault()
        if (filtered[activeIndex]) onSelect(filtered[activeIndex].type)
      } else if (e.key === 'Escape') {
        onClose()
      }
    }
    window.addEventListener('keydown', handler, true)
    return () => window.removeEventListener('keydown', handler, true)
  }, [filtered, activeIndex, onSelect, onClose])

  if (!anchorRect || filtered.length === 0) return null

  const top = anchorRect.bottom + window.scrollY + 4
  const left = anchorRect.left + window.scrollX

  return (
    <div
      ref={listRef}
      className="fixed z-50 w-64 rounded-lg border border-[#e8e8e5] bg-white py-1 shadow-xl"
      style={{ top, left }}
    >
      <p className="px-3 pt-1 pb-1.5 text-[10px] font-semibold uppercase tracking-widest text-[#9b9a97]">
        Blocks
      </p>
      {filtered.map((cmd, i) => (
        <button
          key={cmd.type}
          type="button"
          onMouseDown={(e) => { e.preventDefault(); onSelect(cmd.type) }}
          className={cn(
            'flex w-full items-center gap-3 px-3 py-1.5 text-left transition-colors',
            i === activeIndex ? 'bg-[#f1f0ef]' : 'hover:bg-[#f7f6f3]',
          )}
        >
          <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded border border-[#e3e2e0] bg-white text-[11px] font-bold text-[#37352f]">
            {cmd.icon}
          </span>
          <span className="min-w-0">
            <span className="block text-[13px] font-medium text-[#37352f]">{cmd.label}</span>
            <span className="block text-[11px] text-[#9b9a97]">{cmd.description}</span>
          </span>
        </button>
      ))}
    </div>
  )
}
