'use client'

import { useState } from 'react'
import { cn } from '@/lib/utils/cn'
import { DatetimeInput } from '@/components/ui/datetime-input'
import { useExamStore } from '../exam-store'
import { useGenerateExam, useGradeExam } from '../api/mutations'
import { VocabExamQuestion } from './vocab-exam-question'
import { VocabExamResult } from './vocab-exam-result'
import type { SubmitAnswerItem } from '../types/exam.types'

export function VocabExam() {
  const {
    phase, questionCount, from, to,
    questions, answers, result,
    setConfig, setPhase, initAnswers, setAnswer, setResult, reset,
  } = useExamStore()

  const [validationError, setValidationError] = useState<string | null>(null)

  const generateMutation = useGenerateExam()
  const gradeMutation = useGradeExam()

  const handleStart = async () => {
    if (questionCount < 1) return
    setPhase('loading')
    try {
      const payload: Parameters<typeof generateMutation.mutateAsync>[0] = { questionCount }
      if (from) payload.from = new Date(from + 'T00:00:00Z').toISOString()
      if (to)   payload.to   = new Date(to   + 'T23:59:59Z').toISOString()

      const questions = await generateMutation.mutateAsync(payload)
      initAnswers(questions)
    } catch {
      setPhase('idle')
    }
  }

  const handleSubmit = async () => {
    setValidationError(null)

    const answerList = Object.values(answers)

    const unanswered = answerList.filter((a) => a.answer.trim() === '')
    if (unanswered.length > 0) {
      setValidationError(`${unanswered.length} question(s) still need an answer.`)
      return
    }

    const invalidTf = answerList.filter(
      (a) => a.type === 1 && a.answer !== 'true' && a.answer !== 'false',
    )
    if (invalidTf.length > 0) {
      setValidationError('True/False questions must be answered with "true" or "false".')
      return
    }

    const payload: SubmitAnswerItem[] = answerList.map((a) => ({
      questionId: a.questionId,
      vocabId: a.vocabId,
      type: a.type,
      displayedContent: a.displayedContent,
      answer: a.answer.trim(),
    }))

    setPhase('submitting')
    try {
      const result = await gradeMutation.mutateAsync({ answers: payload })
      setResult(result)
    } catch {
      setPhase('in-progress')
    }
  }

  if (phase === 'result' && result) {
    return <VocabExamResult result={result} onRestart={reset} />
  }

  if (phase === 'idle') {
    return (
      <ExamSetup
        questionCount={questionCount}
        from={from}
        to={to}
        onConfigChange={setConfig}
        onStart={handleStart}
        error={generateMutation.error ? 'Failed to generate questions. Please try again.' : null}
      />
    )
  }

  if (phase === 'loading') {
    return <LoadingScreen message="Generating questions…" />
  }

  if (phase === 'submitting') {
    return <LoadingScreen message="Grading answers…" />
  }

  // in-progress
  const answeredCount = Object.values(answers).filter((a) => a.answer.trim() !== '').length
  const total = questions.length

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-semibold text-gray-900">Vocab Exam</h2>
          <p className="text-sm text-gray-500">{answeredCount} / {total} answered</p>
        </div>
        <button
          type="button"
          onClick={reset}
          className="rounded px-3 py-1.5 text-sm text-gray-500 hover:bg-gray-100 transition-colors"
        >
          Cancel
        </button>
      </div>

      {/* Progress bar */}
      <div className="h-1.5 w-full overflow-hidden rounded-full bg-gray-200">
        <div
          className="h-full rounded-full bg-[#0078d4] transition-all duration-300"
          style={{ width: total > 0 ? `${(answeredCount / total) * 100}%` : '0%' }}
        />
      </div>

      {/* Questions */}
      <div className="flex flex-col gap-4">
        {questions.map((q, i) => (
          <VocabExamQuestion
            key={q.questionId}
            index={i}
            question={q}
            answer={answers[q.questionId]?.answer ?? ''}
            onChange={(val) => setAnswer(q.questionId, val)}
          />
        ))}
      </div>

      {/* Validation error */}
      {validationError && (
        <p className="rounded-md border border-red-200 bg-red-50 px-4 py-2.5 text-sm text-red-600">
          {validationError}
        </p>
      )}

      {/* Submit */}
      <button
        type="button"
        onClick={handleSubmit}
        disabled={gradeMutation.isPending}
        className={cn(
          'w-full rounded-lg py-3 text-sm font-semibold text-white transition-colors',
          answeredCount === total
            ? 'bg-[#0078d4] hover:bg-[#106ebe]'
            : 'bg-gray-300 cursor-not-allowed',
        )}
      >
        Submit Answers
      </button>
    </div>
  )
}

// ── Setup screen ───────────────────────────────────────────────────────────────

interface ExamSetupProps {
  questionCount: number
  from: string
  to: string
  onConfigChange: (patch: { questionCount?: number; from?: string; to?: string }) => void
  onStart: () => void
  error: string | null
}

function ExamSetup({ questionCount, from, to, onConfigChange, onStart, error }: ExamSetupProps) {
  const [dateError, setDateError] = useState<string | null>(null)

  const handleStart = () => {
    setDateError(null)
    if (from && to && new Date(from) > new Date(to)) {
      setDateError('"From" must be on or before "To".')
      return
    }
    onStart()
  }

  return (
    <div className="flex flex-col gap-6 py-4">
      <div className="text-center">
        <h2 className="text-2xl font-bold text-gray-900">Practice Exam</h2>
        <p className="mt-1 text-sm text-gray-500">
          Configure your exam — all filters are optional.
        </p>
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          {/* Question count */}
          <div className="flex flex-col gap-1 sm:col-span-2">
            <label htmlFor="questionCount" className="text-sm font-medium text-gray-700">
              Number of questions <span className="text-gray-400 font-normal">(1–50)</span>
            </label>
            <input
              id="questionCount"
              type="number"
              min={1}
              max={50}
              value={questionCount}
              onChange={(e) => {
                const v = parseInt(e.target.value, 10)
                if (!isNaN(v)) onConfigChange({ questionCount: v })
              }}
              className={cn(
                'h-8 w-full rounded-md border border-[#d9d9d9] bg-white px-3 text-sm text-gray-800 outline-none transition-colors',
                'hover:border-[#4096ff] focus:border-[#1677ff] focus:shadow-[0_0_0_2px_rgba(5,145,255,0.1)]',
              )}
            />
          </div>

          {/* Date range */}
          <DatetimeInput
            type="date"
            label="From date"
            value={from}
            onChange={(e) => onConfigChange({ from: (e.target as HTMLInputElement).value })}
          />
          <DatetimeInput
            type="date"
            label="To date"
            value={to}
            onChange={(e) => onConfigChange({ to: (e.target as HTMLInputElement).value })}
            error={dateError ?? undefined}
          />
        </div>
      </div>

      {error && (
        <p className="rounded-md border border-red-200 bg-red-50 px-4 py-2.5 text-sm text-red-600">
          {error}
        </p>
      )}

      <button
        type="button"
        onClick={handleStart}
        disabled={questionCount < 1 || questionCount > 50}
        className="w-full rounded-lg bg-[#0078d4] py-3 text-sm font-semibold text-white transition hover:bg-[#106ebe] disabled:opacity-50 disabled:cursor-not-allowed"
      >
        Start Exam
      </button>
    </div>
  )
}

// ── Loading screen ─────────────────────────────────────────────────────────────

function LoadingScreen({ message }: { message: string }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-16">
      <div className="h-8 w-8 animate-spin rounded-full border-2 border-gray-200 border-t-[#0078d4]" />
      <p className="text-sm text-gray-500">{message}</p>
    </div>
  )
}
