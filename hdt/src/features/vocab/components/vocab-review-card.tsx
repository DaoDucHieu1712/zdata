'use client'

import { useState } from 'react'
import { cn } from '@/lib/utils/cn'
import { RichTextContent } from '@/components/common/rich-text-content'
import type { Vocab, ReviewStage } from '../types/vocab.types'

export interface VocabReviewCardProps {
  vocab: Vocab
  onReview: (id: string) => void
  isPending?: boolean
}

const NEXT_STAGE_LABEL: Record<ReviewStage, string> = {
  0: 'First review — advances to Day 3',
  1: 'Second review — advances to Day 7',
  2: 'Third review — advances to Day 14',
  3: 'Already completed',
}

export function VocabReviewCard({ vocab, onReview, isPending = false }: VocabReviewCardProps) {
  const [revealed, setReveal] = useState(false)

  return (
    <div className={cn(
      'rounded-xl border bg-white p-5 shadow-sm transition-shadow hover:shadow-md',
      vocab.isCompleted ? 'border-green-200 bg-green-50' : 'border-gray-200',
    )}>
      {/* Word */}
      <div className="mb-3">
        <h3 className="text-2xl font-bold tracking-tight text-gray-900">{vocab.word}</h3>
      </div>

      {/* Content — hidden until revealed */}
      {revealed ? (
        <RichTextContent html={vocab.content} />
      ) : (
        <button
          type="button"
          onClick={() => setReveal(true)}
          className="w-full rounded-md border border-dashed border-gray-300 py-3 text-sm text-gray-400 hover:border-blue-300 hover:text-blue-500"
        >
          Tap to reveal content
        </button>
      )}

      {/* Footer */}
      <div className="mt-4 flex items-center justify-between border-t border-gray-100 pt-3">
        <span className="text-xs text-gray-400">{NEXT_STAGE_LABEL[vocab.reviewStage]}</span>
        {!vocab.isCompleted && (
          <button
            type="button"
            onClick={() => onReview(vocab.id)}
            disabled={isPending}
            className="rounded-md bg-green-600 px-4 py-1.5 text-sm font-medium text-white transition hover:bg-green-700 disabled:opacity-60"
          >
            {isPending ? 'Saving…' : 'Mark Reviewed'}
          </button>
        )}
        {vocab.isCompleted && (
          <span className="text-xs font-medium text-green-600">Completed</span>
        )}
      </div>
    </div>
  )
}
