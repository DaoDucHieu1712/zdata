'use client'

import { cn } from '@/lib/utils/cn'
import { useFlashcardStore } from '../flashcard-store'

const REVIEW_STAGE_OPTIONS = [
  { value: '', label: 'All stages' },
  { value: '0', label: 'New' },
  { value: '1', label: 'Day 3' },
  { value: '2', label: 'Day 7' },
  { value: '3', label: 'Mastered' },
]

interface VocabFlashcardConfigProps {
  onStart: () => void
  error?: string | null
}

export function VocabFlashcardConfig({ onStart, error }: VocabFlashcardConfigProps) {
  const { count, reviewStage, useDaily, setConfig } = useFlashcardStore()

  return (
    <div className="flex flex-col gap-6">
      <div className="rounded-xl border border-[#e1dfdd] bg-white p-6 shadow-sm">
        <h2 className="mb-5 text-base font-semibold text-[#323130]">Session Setup</h2>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          {/* Card count */}
          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-medium text-[#605e5c]">Number of Cards</label>
            <input
              type="number"
              min={1}
              max={100}
              value={count}
              onChange={(e) => {
                const n = parseInt(e.target.value, 10)
                setConfig({ count: isNaN(n) ? 1 : Math.max(1, Math.min(100, n)) })
              }}
              className="h-9 rounded-md border border-[#d2d0ce] px-3 text-sm text-[#323130] outline-none focus:border-[#0078d4] focus:ring-1 focus:ring-[#0078d4]"
            />
          </div>

          {/* Review stage */}
          <div className="flex flex-col gap-1.5">
            <label className={cn('text-xs font-medium', useDaily ? 'text-[#a19f9d]' : 'text-[#605e5c]')}>
              Review Stage
            </label>
            <select
              disabled={useDaily}
              value={reviewStage !== null && reviewStage !== undefined ? String(reviewStage) : ''}
              onChange={(e) =>
                setConfig({ reviewStage: e.target.value === '' ? null : parseInt(e.target.value, 10) })
              }
              className={cn(
                'h-9 rounded-md border border-[#d2d0ce] bg-white px-3 text-sm outline-none focus:border-[#0078d4] focus:ring-1 focus:ring-[#0078d4]',
                useDaily ? 'cursor-not-allowed bg-[#f7f6f3] text-[#a19f9d]' : 'text-[#323130]',
              )}
            >
              {REVIEW_STAGE_OPTIONS.map((o) => (
                <option key={o.value} value={o.value}>{o.label}</option>
              ))}
            </select>
          </div>

          {/* Use daily toggle */}
          <div className="flex items-end pb-1 sm:col-span-2">
            <label className="flex cursor-pointer items-center gap-2 select-none">
              <input
                type="checkbox"
                checked={useDaily}
                onChange={(e) =>
                  setConfig({
                    useDaily: e.target.checked,
                    reviewStage: e.target.checked ? null : reviewStage,
                  })
                }
                className="h-4 w-4 cursor-pointer rounded border-[#c8c6c4] accent-[#0078d4]"
              />
              <span className="text-sm text-[#323130]">Use today&apos;s review list</span>
            </label>
          </div>
        </div>

        {error && (
          <p className="mt-4 rounded-md bg-[#fde7e9] px-3 py-2 text-sm text-[#d13438]">{error}</p>
        )}
      </div>

      <button
        type="button"
        onClick={onStart}
        className="w-full rounded-lg bg-[#0078d4] py-3 text-sm font-semibold text-white transition-colors hover:bg-[#106ebe] active:scale-[0.99]"
      >
        Start Flashcards
      </button>
    </div>
  )
}
