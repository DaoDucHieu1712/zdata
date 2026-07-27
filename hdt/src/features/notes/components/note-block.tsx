'use client'

import { useEffect, useRef } from 'react'
import { cn } from '@/lib/utils/cn'
import type { BlockType } from '../types/notes.types'

export interface BlockState {
  id: string
  type: BlockType
  checked?: boolean
  language?: string
}

interface NoteBlockProps {
  block: BlockState
  initialContent: string
  listNumber?: number        // for numberedList
  placeholder?: string
  onRef: (id: string, el: HTMLElement | null) => void
  onInput: (id: string) => void
  onKeyDown: (id: string, e: React.KeyboardEvent) => void
  onCheck: (id: string, checked: boolean) => void
  autoFocus?: boolean
}

const PLACEHOLDER_CLS = 'empty:before:content-[attr(data-placeholder)] empty:before:text-[#c1bfbc] empty:before:pointer-events-none'

export function NoteBlock({
  block,
  initialContent,
  listNumber,
  placeholder,
  onRef,
  onInput,
  onKeyDown,
  onCheck,
  autoFocus,
}: NoteBlockProps) {
  const elRef = useRef<HTMLElement | null>(null)
  const initRef = useRef(initialContent)

  const setRef = (el: HTMLElement | null) => {
    if (el && !elRef.current) {
      el.textContent = initRef.current
      if (autoFocus) {
        el.focus()
        const range = document.createRange()
        const sel = window.getSelection()
        range.selectNodeContents(el)
        range.collapse(false)
        sel?.removeAllRanges()
        sel?.addRange(range)
      }
    }
    elRef.current = el
    onRef(block.id, el)
  }

  // Re-initialize when content needs reset (e.g., note load)
  useEffect(() => {
    if (elRef.current && elRef.current.textContent !== initRef.current) {
      // only set if ref already mounted (from parent calling initContent)
    }
  }, [])

  const editableProps = {
    contentEditable: true as const,
    suppressContentEditableWarning: true,
    'data-placeholder': placeholder ?? 'Type "/" for commands…',
    onInput: () => onInput(block.id),
    onKeyDown: (e: React.KeyboardEvent) => onKeyDown(block.id, e),
  }

  if (block.type === 'divider') {
    return <hr className="my-2 border-[#e9e9e7]" />
  }

  if (block.type === 'heading1') {
    return (
      <h1
        ref={setRef as (el: HTMLHeadingElement | null) => void}
        {...editableProps}
        data-placeholder="Heading 1"
        className={cn('text-[1.875rem] font-bold text-[#37352f] outline-none leading-tight', PLACEHOLDER_CLS)}
      />
    )
  }

  if (block.type === 'heading2') {
    return (
      <h2
        ref={setRef as (el: HTMLHeadingElement | null) => void}
        {...editableProps}
        data-placeholder="Heading 2"
        className={cn('text-[1.5rem] font-semibold text-[#37352f] outline-none leading-snug', PLACEHOLDER_CLS)}
      />
    )
  }

  if (block.type === 'heading3') {
    return (
      <h3
        ref={setRef as (el: HTMLHeadingElement | null) => void}
        {...editableProps}
        data-placeholder="Heading 3"
        className={cn('text-[1.25rem] font-semibold text-[#37352f] outline-none leading-snug', PLACEHOLDER_CLS)}
      />
    )
  }

  if (block.type === 'code') {
    return (
      <pre className="rounded-md bg-[#f7f6f3] px-4 py-3">
        <code
          ref={setRef as (el: HTMLElement | null) => void}
          {...editableProps}
          data-placeholder="Write code…"
          className={cn(
            'block font-mono text-[13px] text-[#eb5757] outline-none whitespace-pre-wrap break-all',
            PLACEHOLDER_CLS,
          )}
        />
      </pre>
    )
  }

  if (block.type === 'bulletList') {
    return (
      <div className="flex items-start gap-2">
        <span className="mt-[3px] shrink-0 text-[#9b9a97]">•</span>
        <p
          ref={setRef as (el: HTMLParagraphElement | null) => void}
          {...editableProps}
          className={cn('flex-1 text-[15px] leading-relaxed text-[#37352f] outline-none', PLACEHOLDER_CLS)}
        />
      </div>
    )
  }

  if (block.type === 'numberedList') {
    return (
      <div className="flex items-start gap-2">
        <span className="mt-[3px] shrink-0 min-w-[1.25rem] text-right text-[#9b9a97] text-[15px]">
          {listNumber ?? 1}.
        </span>
        <p
          ref={setRef as (el: HTMLParagraphElement | null) => void}
          {...editableProps}
          className={cn('flex-1 text-[15px] leading-relaxed text-[#37352f] outline-none', PLACEHOLDER_CLS)}
        />
      </div>
    )
  }

  if (block.type === 'todo') {
    return (
      <div className="flex items-start gap-2">
        <input
          type="checkbox"
          checked={block.checked ?? false}
          onChange={(e) => onCheck(block.id, e.target.checked)}
          className="mt-1 h-4 w-4 shrink-0 cursor-pointer rounded border-[#c8c6c4] accent-[#0078d4]"
        />
        <p
          ref={setRef as (el: HTMLParagraphElement | null) => void}
          {...editableProps}
          data-placeholder="To-do"
          className={cn(
            'flex-1 text-[15px] leading-relaxed outline-none',
            PLACEHOLDER_CLS,
            block.checked ? 'text-[#9b9a97] line-through' : 'text-[#37352f]',
          )}
        />
      </div>
    )
  }

  // paragraph (default)
  return (
    <p
      ref={setRef as (el: HTMLParagraphElement | null) => void}
      {...editableProps}
      className={cn('text-[15px] leading-relaxed text-[#37352f] outline-none', PLACEHOLDER_CLS)}
    />
  )
}
