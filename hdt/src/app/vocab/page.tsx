'use client'

import { useState } from 'react'
import { VocabList, VocabDaily, VocabExam, VocabFlashcard } from '@/features/vocab'
import { cn } from '@/lib/utils/cn'

type Tab =  'list' |'daily' | 'exam' | 'flashcard'

const TAB_LABELS: Record<Tab, string> = {
  list:      'All Words',
  daily:     'Daily Mission',
  exam:      'Practice Exam',
  flashcard: 'Flashcards',
}

export default function VocabPage() {
  const [tab, setTab] = useState<Tab>('list')

  return (
    <div className="flex flex-col gap-6">
      {/* Page header */}
      <div>
        <h1 className="text-xl font-semibold text-[#323130]">Vocabulary</h1>
        <p className="mt-0.5 text-sm text-[#605e5c]">
          Spaced-repetition review — day 3, 7, and 14.
        </p>
      </div>

      {/* Tab switcher */}
      <div className="flex gap-0 border-b border-[#e1dfdd]">
        {(['daily', 'list', 'exam', 'flashcard'] as Tab[]).map((t) => (
          <button
            key={t}
            type="button"
            onClick={() => setTab(t)}
            className={cn(
              'px-4 py-2 text-sm font-medium transition-colors border-b-2 -mb-px',
              tab === t
                ? 'border-[#0078d4] text-[#0078d4]'
                : 'border-transparent text-[#605e5c] hover:text-[#323130] hover:border-[#c8c6c4]',
            )}
          >
            {TAB_LABELS[t]}
          </button>
        ))}
      </div>

      {tab === 'list'      && <VocabList />}
      {tab === 'daily'     && <VocabDaily />}
      {tab === 'exam'      && (
        <div className="mx-auto w-full max-w-2xl">
          <VocabExam />
        </div>
      )}
      {tab === 'flashcard' && (
        <div className="mx-auto w-full max-w-2xl">
          <VocabFlashcard />
        </div>
      )}
    </div>
  )
}
