'use client'

import { useState, useEffect } from 'react'
import { cn } from '@/lib/utils/cn'

export interface RichTextContentProps {
  html?: string | null
  className?: string
  truncate?: boolean
}

export function RichTextContent({ html, className, truncate }: RichTextContentProps) {
  // Initialize with raw html so SSR and hydration match (no mismatch).
  // useEffect then sanitizes on the client after mount.
  const [clean, setClean] = useState<string>(html ?? '')

  useEffect(() => {
    if (!html) { setClean(''); return }
    import('dompurify').then(({ default: DOMPurify }) => {
      setClean(DOMPurify.sanitize(html))
    })
  }, [html])

  if (!html) return <span className="text-gray-300">—</span>

  return (
    <div
      className={cn(
        // Explicit element styles — no @tailwindcss/typography required
        'text-sm text-[#323130]',
        '[&_p]:my-1.5 [&_p:first-child]:mt-0 [&_p:last-child]:mb-0',
        '[&_strong]:font-semibold [&_em]:italic',
        '[&_ul]:list-disc [&_ul]:pl-4 [&_ul]:my-1.5',
        '[&_ol]:list-decimal [&_ol]:pl-4 [&_ol]:my-1.5',
        '[&_li]:my-0.5',
        '[&_h1]:text-xl [&_h1]:font-bold [&_h1]:my-2',
        '[&_h2]:text-lg [&_h2]:font-semibold [&_h2]:my-1.5',
        '[&_h3]:text-base [&_h3]:font-semibold [&_h3]:my-1',
        truncate && 'line-clamp-2 overflow-hidden',
        className,
      )}
      dangerouslySetInnerHTML={{ __html: clean }}
    />
  )
}

export function stripHtml(html: string): string {
  if (typeof window === 'undefined') return html.replace(/<[^>]*>/g, '')
  const doc = new DOMParser().parseFromString(html, 'text/html')
  return doc.body.textContent ?? ''
}
