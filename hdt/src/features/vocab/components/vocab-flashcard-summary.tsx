'use client'

import { cn } from '@/lib/utils/cn'
import { stripHtml } from '@/components/common/rich-text-content'
import { useFlashcardStore } from '../flashcard-store'

export function VocabFlashcardSummary() {
  const { sessionResult, deck, results, reset, startSession } = useFlashcardStore()

  if (!sessionResult) return null

  const { knewCount, totalCards } = sessionResult
  const pct = totalCards > 0 ? Math.round((knewCount / totalCards) * 100) : 0
  const grade = pct >= 80 ? 'great' : pct >= 50 ? 'ok' : 'poor'

  const gradeStyle = {
    great: { ring: 'ring-[#107c10]', score: 'text-[#107c10]', bg: 'bg-[#dff6dd]', msg: 'Excellent work!' },
    ok:    { ring: 'ring-[#c7900e]', score: 'text-[#c7900e]', bg: 'bg-[#fff4ce]', msg: 'Good progress!' },
    poor:  { ring: 'ring-[#d13438]', score: 'text-[#d13438]', bg: 'bg-[#fde7e9]', msg: 'Keep practicing!' },
  }[grade]

  const missedCards = deck.filter((card) =>
    results.some((r) => r.vocabId === card.vocabId && !r.knew)
  )

  return (
    <div className="flex flex-col gap-6">
      {/* Score card */}
      <div className={cn('flex flex-col items-center gap-3 rounded-xl px-8 py-10', gradeStyle.bg)}>
        <div className={cn('flex h-20 w-20 items-center justify-center rounded-full bg-white ring-4', gradeStyle.ring)}>
          <span className={cn('text-2xl font-bold', gradeStyle.score)}>{pct}%</span>
        </div>
        <p className="text-base font-semibold text-[#323130]">
          {knewCount} / {totalCards} cards known
        </p>
        <p className="text-sm text-[#605e5c]">{gradeStyle.msg}</p>
      </div>

      {/* Missed words list */}
      {missedCards.length > 0 && (
        <div className="flex flex-col gap-2">
          <p className="text-sm font-semibold text-[#323130]">
            Review These ({missedCards.length})
          </p>
          <div className="overflow-hidden rounded-lg border border-[#e1dfdd] bg-white">
            {missedCards.map((card, i) => (
              <div
                key={card.vocabId}
                className={cn(
                  'flex items-baseline gap-3 px-4 py-3',
                  i < missedCards.length - 1 && 'border-b border-[#f0f0f0]',
                )}
              >
                <span className="shrink-0 text-sm font-medium text-[#323130]">{card.word}</span>
                {card.content && (
                  <span className="min-w-0 truncate text-xs text-[#605e5c]">
                    {stripHtml(card.content)}
                  </span>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Action buttons */}
      <div className="flex gap-3">
        <button
          type="button"
          onClick={reset}
          className="flex-1 rounded-lg border border-[#e1dfdd] bg-white py-3 text-sm font-medium text-[#323130] transition-colors hover:bg-[#f7f6f3]"
        >
          New Session
        </button>
        {missedCards.length > 0 && (
          <button
            type="button"
            onClick={() => startSession(missedCards)}
            className="flex-1 rounded-lg bg-[#0078d4] py-3 text-sm font-medium text-white transition-colors hover:bg-[#106ebe]"
          >
            Study Missed ({missedCards.length})
          </button>
        )}
      </div>
    </div>
  )
}
