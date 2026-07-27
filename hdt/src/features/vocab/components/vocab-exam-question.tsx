'use client'

import { cn } from '@/lib/utils/cn'
import { RichTextContent, stripHtml } from '@/components/common/rich-text-content'
import type { ExamQuestion } from '../types/exam.types'

export interface VocabExamQuestionProps {
  index: number
  question: ExamQuestion
  answer: string
  onChange: (answer: string) => void
}

export function VocabExamQuestion({ index, question, answer, onChange }: VocabExamQuestionProps) {
  return (
    <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
      <div className="mb-4 flex items-start gap-3">
        <span className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-[#0078d4] text-xs font-semibold text-white">
          {index + 1}
        </span>
        <div className="flex-1">
          <p className="text-xs font-medium uppercase tracking-wide text-gray-400">
            {QUESTION_TYPE_LABEL[question.type]}
          </p>
          <h3 className="mt-0.5 text-xl font-bold text-gray-900">{question.word}</h3>
        </div>
      </div>

      {question.type === 0 && question.options && (
        <MultipleChoiceInput
          options={question.options}
          value={answer}
          onChange={onChange}
        />
      )}

      {question.type === 1 && question.displayedContent !== null && (
        <TrueFalseInput
          displayedContent={question.displayedContent}
          value={answer}
          onChange={onChange}
        />
      )}

      {question.type === 2 && (
        <WrittenInput value={answer} onChange={onChange} />
      )}
    </div>
  )
}

// ── Sub-renderers ──────────────────────────────────────────────────────────────

const QUESTION_TYPE_LABEL: Record<0 | 1 | 2, string> = {
  0: 'Multiple choice',
  1: 'True / False',
  2: 'Written',
}

interface MultipleChoiceInputProps {
  options: string[]
  value: string
  onChange: (v: string) => void
}

function MultipleChoiceInput({ options, value, onChange }: MultipleChoiceInputProps) {
  return (
    <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
      {options.map((opt) => {
        const displayText = opt.startsWith('<') ? stripHtml(opt) : opt
        return (
          <button
            key={opt}
            type="button"
            onClick={() => onChange(opt)}
            className={cn(
              'rounded-lg border px-4 py-3 text-left text-sm transition-colors',
              value === opt
                ? 'border-[#0078d4] bg-[#deecf9] text-[#0078d4] font-medium'
                : 'border-gray-200 text-gray-700 hover:border-[#0078d4] hover:bg-[#f3f9ff]',
            )}
          >
            {displayText}
          </button>
        )
      })}
    </div>
  )
}

interface TrueFalseInputProps {
  displayedContent: string
  value: string
  onChange: (v: string) => void
}

function TrueFalseInput({ displayedContent, value, onChange }: TrueFalseInputProps) {
  return (
    <div className="flex flex-col gap-3">
      <div className="rounded-md bg-gray-50 px-4 py-3 text-sm text-gray-700">
        <span className="mr-1 font-medium text-gray-500">Content shown:</span>
        <RichTextContent html={displayedContent} className="inline" />
      </div>
      <div className="flex gap-3">
        {(['true', 'false'] as const).map((v) => (
          <button
            key={v}
            type="button"
            onClick={() => onChange(v)}
            className={cn(
              'flex-1 rounded-lg border py-2.5 text-sm font-medium transition-colors',
              value === v
                ? v === 'true'
                  ? 'border-green-500 bg-green-50 text-green-700'
                  : 'border-red-400 bg-red-50 text-red-600'
                : 'border-gray-200 text-gray-700 hover:border-gray-400',
            )}
          >
            {v === 'true' ? 'True' : 'False'}
          </button>
        ))}
      </div>
    </div>
  )
}

interface WrittenInputProps {
  value: string
  onChange: (v: string) => void
}

function WrittenInput({ value, onChange }: WrittenInputProps) {
  return (
    <input
      type="text"
      value={value}
      onChange={(e) => onChange(e.target.value)}
      placeholder="Type the meaning…"
      className={cn(
        'h-10 w-full rounded-md border border-[#d9d9d9] bg-white px-3 text-sm text-gray-800 outline-none transition-colors placeholder:text-gray-400',
        'hover:border-[#4096ff]',
        'focus:border-[#1677ff] focus:shadow-[0_0_0_2px_rgba(5,145,255,0.1)]',
      )}
    />
  )
}
