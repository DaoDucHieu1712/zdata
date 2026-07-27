'use client'

import { useEffect } from 'react'
import { cn } from '@/lib/utils/cn'
import { RichTextContent } from '@/components/common/rich-text-content'
import { useFlashcardStore } from '../flashcard-store'

interface VocabFlashcardCardProps {
  onAnswer: (knew: boolean) => void
}

export function VocabFlashcardCard({ onAnswer }: VocabFlashcardCardProps) {
  const { deck, currentIndex, isFlipped, flip } = useFlashcardStore()
  const card = deck[currentIndex]

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.code === 'Space') { e.preventDefault(); flip() }
      if (isFlipped && e.code === 'ArrowRight') onAnswer(true)
      if (isFlipped && e.code === 'ArrowLeft') onAnswer(false)
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [isFlipped, flip, onAnswer])

  if (!card) return null

  const progress = currentIndex / deck.length

  return (
    <div className="flex flex-col gap-5">
      {/* Progress bar */}
      <div className="flex items-center gap-3">
        <div className="flex-1 overflow-hidden rounded-full bg-[#e1dfdd] h-1.5">
          <div
            className="h-full rounded-full bg-[#0078d4] transition-all duration-300"
            style={{ width: `${progress * 100}%` }}
          />
        </div>
        <span className="shrink-0 tabular-nums text-xs text-[#605e5c]">
          {currentIndex} / {deck.length}
        </span>
      </div>

      {/* Flip card */}
      <div
        className="[perspective:1200px] w-full cursor-pointer"
        onClick={() => { if (!isFlipped) flip() }}
        role="button"
        tabIndex={0}
        onKeyDown={(e) => { if (e.code === 'Enter' && !isFlipped) flip() }}
        aria-label={isFlipped ? 'Card back' : 'Card front — click to flip'}
      >
        <div
          className={cn(
            'relative w-full min-h-[280px] transition-transform duration-500 [transform-style:preserve-3d]',
            isFlipped && '[transform:rotateY(180deg)]',
          )}
        >
          {/* Front — word */}
          <div className="absolute inset-0 [backface-visibility:hidden] flex flex-col items-center justify-center gap-3 rounded-xl border border-[#e1dfdd] bg-white px-8 py-10 shadow-sm select-none">
            <p className="text-center text-3xl font-bold text-[#323130]">{card.word}</p>
            <p className="mt-2 text-xs text-[#a19f9d]">Click to reveal · Space</p>
          </div>

          {/* Back — content (HTML) */}
          <div className="absolute inset-0 [backface-visibility:hidden] [transform:rotateY(180deg)] flex flex-col gap-4 overflow-y-auto rounded-xl border border-[#0078d4] bg-[#f0f7ff] px-8 py-8 shadow-sm select-none">
            <RichTextContent
              html={card.content}
              className="text-base"
            />
          </div>
        </div>
      </div>

      {/* Action buttons — visible only when flipped */}
      <div
        className={cn(
          'flex gap-3 transition-opacity duration-300',
          isFlipped ? 'opacity-100' : 'pointer-events-none opacity-0',
        )}
      >
        <button
          type="button"
          onClick={() => onAnswer(false)}
          className="flex flex-1 items-center justify-center gap-1.5 rounded-lg border border-[#d13438] bg-white py-3 text-sm font-medium text-[#d13438] transition-colors hover:bg-[#fde7e9] active:scale-[0.98]"
        >
          ✗ Don&apos;t Know
          <span className="text-xs opacity-40">←</span>
        </button>
        <button
          type="button"
          onClick={() => onAnswer(true)}
          className="flex flex-1 items-center justify-center gap-1.5 rounded-lg border border-[#107c10] bg-white py-3 text-sm font-medium text-[#107c10] transition-colors hover:bg-[#dff6dd] active:scale-[0.98]"
        >
          ✓ Know
          <span className="text-xs opacity-40">→</span>
        </button>
      </div>

      {/* Flip button — visible only when not flipped */}
      {!isFlipped && (
        <div className="flex justify-center">
          <button
            type="button"
            onClick={flip}
            className="rounded-lg bg-[#0078d4] px-6 py-2.5 text-sm font-medium text-white transition-colors hover:bg-[#106ebe]"
          >
            Flip Card
          </button>
        </div>
      )}
    </div>
  )
}
