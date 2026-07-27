'use client'

import { cn } from '@/lib/utils/cn'
import type { ExamResult } from '../types/exam.types'

export interface VocabExamResultProps {
  result: ExamResult
  onRestart: () => void
}

export function VocabExamResult({ result, onRestart }: VocabExamResultProps) {
  const { totalQuestions, correctCount, score, results } = result
  const scoreColor =
    score >= 80 ? 'text-green-600' : score >= 50 ? 'text-yellow-600' : 'text-red-500'

  return (
    <div className="flex flex-col gap-6">
      {/* Score card */}
      <div className="rounded-xl border border-gray-200 bg-white p-6 text-center shadow-sm">
        <p className="text-sm font-medium text-gray-500">Your Score</p>
        <p className={cn('mt-1 text-6xl font-bold tabular-nums', scoreColor)}>
          {score.toFixed(0)}%
        </p>
        <p className="mt-2 text-sm text-gray-500">
          {correctCount} / {totalQuestions} correct
        </p>
        <button
          type="button"
          onClick={onRestart}
          className="mt-5 rounded-md bg-[#0078d4] px-6 py-2 text-sm font-medium text-white transition hover:bg-[#106ebe]"
        >
          Try Again
        </button>
      </div>

      {/* Per-question breakdown */}
      <div className="flex flex-col gap-3">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-gray-500">
          Question Breakdown
        </h2>
        {results.map((r, i) => (
          <div
            key={r.questionId}
            className={cn(
              'rounded-xl border bg-white p-4 shadow-sm',
              r.isCorrect ? 'border-green-200' : 'border-red-200',
            )}
          >
            <div className="flex items-start gap-3">
              <span
                className={cn(
                  'mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full text-xs font-bold',
                  r.isCorrect
                    ? 'bg-green-100 text-green-700'
                    : 'bg-red-100 text-red-600',
                )}
              >
                {r.isCorrect ? '✓' : '✗'}
              </span>
              <div className="flex-1 min-w-0">
                <div className="flex items-baseline justify-between gap-2">
                  <span className="text-xs text-gray-400">Q{i + 1}</span>
                  <span className="font-semibold text-gray-900">{r.word}</span>
                </div>

                {!r.isCorrect && (
                  <div className="mt-2 grid grid-cols-1 gap-1 sm:grid-cols-2">
                    <div className="rounded-md bg-red-50 px-3 py-1.5 text-xs">
                      <span className="font-medium text-red-600">Your answer: </span>
                      <span className="text-red-700">{r.submittedAnswer || '(blank)'}</span>
                    </div>
                    <div className="rounded-md bg-green-50 px-3 py-1.5 text-xs">
                      <span className="font-medium text-green-600">Correct: </span>
                      <span className="text-green-700">{r.correctAnswer}</span>
                    </div>
                  </div>
                )}

                {r.isCorrect && (
                  <p className="mt-1 text-xs text-green-600">{r.correctAnswer}</p>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
