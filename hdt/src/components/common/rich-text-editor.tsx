'use client'

import { useEditor, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import { cn } from '@/lib/utils/cn'

export interface RichTextEditorProps {
  value?: string
  onChange?: (html: string) => void
  placeholder?: string
  label?: string
  error?: string
  className?: string
}

const TOOLBAR_BTN = 'rounded px-1.5 py-0.5 text-xs font-medium transition-colors hover:bg-[#f3f2f1] disabled:opacity-40'
const TOOLBAR_ACTIVE = 'bg-[#deecf9] text-[#0078d4]'

export function RichTextEditor({ value, onChange, placeholder, label, error, className }: RichTextEditorProps) {
  const editor = useEditor({
    extensions: [StarterKit],
    content: value ?? '',
    editorProps: {
      attributes: {
        class: 'outline-none min-h-[160px] px-3 py-2.5 text-sm text-[#323130] [&_p]:my-1 [&_ul]:list-disc [&_ul]:pl-4 [&_ol]:list-decimal [&_ol]:pl-4',
      },
    },
    onUpdate: ({ editor }) => {
      const html = editor.getHTML()
      onChange?.(html === '<p></p>' ? '' : html)
    },
  })

  return (
    <div className={cn('flex flex-col gap-1', className)}>
      {label && (
        <label className="text-xs font-medium text-[#605e5c]">{label}</label>
      )}
      <div
        className={cn(
          'rounded-md border bg-white',
          error ? 'border-[#d13438]' : 'border-[#d2d0ce] focus-within:border-[#0078d4] focus-within:ring-1 focus-within:ring-[#0078d4]',
        )}
      >
        {/* Toolbar */}
        <div className="flex flex-wrap gap-0.5 border-b border-[#e1dfdd] px-2 py-1.5">
          <button
            type="button"
            onClick={() => editor?.chain().focus().toggleBold().run()}
            disabled={!editor?.can().toggleBold()}
            className={cn(TOOLBAR_BTN, editor?.isActive('bold') && TOOLBAR_ACTIVE)}
            title="Bold"
          >
            <strong>B</strong>
          </button>
          <button
            type="button"
            onClick={() => editor?.chain().focus().toggleItalic().run()}
            disabled={!editor?.can().toggleItalic()}
            className={cn(TOOLBAR_BTN, editor?.isActive('italic') && TOOLBAR_ACTIVE)}
            title="Italic"
          >
            <em>I</em>
          </button>
          <div className="mx-1 w-px self-stretch bg-[#e1dfdd]" />
          <button
            type="button"
            onClick={() => editor?.chain().focus().toggleBulletList().run()}
            className={cn(TOOLBAR_BTN, editor?.isActive('bulletList') && TOOLBAR_ACTIVE)}
            title="Bullet list"
          >
            •≡
          </button>
          <button
            type="button"
            onClick={() => editor?.chain().focus().toggleOrderedList().run()}
            className={cn(TOOLBAR_BTN, editor?.isActive('orderedList') && TOOLBAR_ACTIVE)}
            title="Ordered list"
          >
            1≡
          </button>
          <div className="mx-1 w-px self-stretch bg-[#e1dfdd]" />
          <button
            type="button"
            onClick={() => editor?.chain().focus().setParagraph().run()}
            className={cn(TOOLBAR_BTN, editor?.isActive('paragraph') && TOOLBAR_ACTIVE)}
            title="Paragraph"
          >
            P
          </button>
          <button
            type="button"
            onClick={() => editor?.chain().focus().toggleHeading({ level: 3 }).run()}
            className={cn(TOOLBAR_BTN, editor?.isActive('heading', { level: 3 }) && TOOLBAR_ACTIVE)}
            title="Heading"
          >
            H
          </button>
        </div>

        {/* Editor area */}
        <div className="relative">
          {editor?.isEmpty && placeholder && (
            <p className="pointer-events-none absolute left-3 top-2.5 text-sm text-[#a19f9d]">
              {placeholder}
            </p>
          )}
          <EditorContent editor={editor} />
        </div>
      </div>

      {error && (
        <p className="text-xs text-[#d13438]">{error}</p>
      )}
    </div>
  )
}
