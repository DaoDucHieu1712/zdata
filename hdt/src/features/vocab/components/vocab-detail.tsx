'use client'

import Link from 'next/link'
import { RichTextContent } from '@/components/common/rich-text-content'
import { cn } from '@/lib/utils/cn'
import { ROUTES } from '@/config/routes'
import type { Vocab } from '../types/vocab.types'

export interface VocabDetailProps {
  vocab: Vocab
}

const STAGES = [
  { step: 0, label: 'New' },
  { step: 1, label: 'Day 3' },
  { step: 2, label: 'Day 7' },
  { step: 3, label: 'Done' },
] as const

const STAGE_COLOR: Record<number, string> = {
  0: 'text-[#605e5c]',
  1: 'text-[#0078d4]',
  2: 'text-[#8a6c00]',
  3: 'text-[#107c10]',
}

const STAGE_BG: Record<number, string> = {
  0: 'bg-[#f3f2f1]',
  1: 'bg-[#0078d4]',
  2: 'bg-[#fce100]',
  3: 'bg-[#107c10]',
}

function StageProgress({ stage }: { stage: number }) {
  return (
    <div className="flex items-center gap-0">
      {STAGES.map(({ step, label }, i) => {
        const done = step < stage
        const active = step === stage
        return (
          <div key={step} className="flex items-center">
            <div className="flex flex-col items-center gap-1">
              <div
                className={cn(
                  'h-2 w-2 rounded-full transition-all',
                  done
                    ? 'bg-[#107c10]'
                    : active
                    ? STAGE_BG[stage]
                    : 'bg-[#e1dfdd]',
                )}
              />
              <span
                className={cn(
                  'text-[10px] font-medium',
                  active ? STAGE_COLOR[stage] : done ? 'text-[#107c10]' : 'text-[#c8c6c4]',
                )}
              >
                {label}
              </span>
            </div>
            {i < STAGES.length - 1 && (
              <div
                className={cn(
                  'mb-3.5 h-px w-10',
                  done ? 'bg-[#107c10]' : 'bg-[#e1dfdd]',
                )}
              />
            )}
          </div>
        )
      })}
    </div>
  )
}

function StatCard({
  label,
  value,
  sub,
  highlight,
}: {
  label: string
  value: React.ReactNode
  sub?: string
  highlight?: boolean
}) {
  return (
    <div
      className={cn(
        'rounded-lg border px-4 py-3',
        highlight
          ? 'border-[#bad7f2] bg-[#f0f6fc]'
          : 'border-[#e1dfdd] bg-white',
      )}
    >
      <p className="text-[11px] font-medium uppercase tracking-wide text-[#a19f9d]">{label}</p>
      <p className={cn('mt-1 text-[13px] font-semibold', highlight ? 'text-[#0078d4]' : 'text-[#323130]')}>
        {value}
      </p>
      {sub && <p className="mt-0.5 text-[11px] text-[#a19f9d]">{sub}</p>}
    </div>
  )
}

function fmt(iso: string) {
  return new Date(iso).toLocaleDateString(undefined, { dateStyle: 'medium' })
}

export function VocabDetail({ vocab }: VocabDetailProps) {
  const nextReviewLabel = vocab.isCompleted
    ? 'Completed'
    : vocab.nextReviewAt
    ? fmt(vocab.nextReviewAt)
    : '—'

  return (
    <div className="flex flex-col gap-5 max-w-3xl">
      {/* Hero card */}
      <div className="rounded-xl border border-[#e1dfdd] bg-white shadow-sm overflow-hidden">
        <div className="flex items-start justify-between gap-4 px-6 pt-6 pb-4">
          <div className="flex flex-col gap-3">
            <h1 className="text-4xl font-bold tracking-tight text-[#201f1e]">
              {vocab.word}
            </h1>
            <StageProgress stage={vocab.reviewStage} />
          </div>

          <Link
            href={ROUTES.VOCAB_EDIT(vocab.id)}
            className="shrink-0 rounded-lg border border-[#e1dfdd] px-4 py-2 text-[13px] font-medium text-[#323130] hover:border-[#0078d4] hover:text-[#0078d4] hover:bg-[#f0f6fc] transition-all"
          >
            Edit
          </Link>
        </div>

        {/* Divider + stats row */}
        <div className="border-t border-[#f3f2f1] grid grid-cols-3 divide-x divide-[#f3f2f1]">
          <div className="px-5 py-3">
            <p className="text-[11px] font-medium uppercase tracking-wide text-[#a19f9d]">Stage</p>
            <p className={cn('mt-0.5 text-sm font-semibold', STAGE_COLOR[vocab.reviewStage])}>
              {STAGES[vocab.reviewStage]?.label ?? '—'}
            </p>
          </div>
          <div className="px-5 py-3">
            <p className="text-[11px] font-medium uppercase tracking-wide text-[#a19f9d]">Next review</p>
            <p className={cn('mt-0.5 text-sm font-semibold', vocab.isCompleted ? 'text-[#107c10]' : 'text-[#323130]')}>
              {nextReviewLabel}
            </p>
          </div>
          <div className="px-5 py-3">
            <p className="text-[11px] font-medium uppercase tracking-wide text-[#a19f9d]">Last reviewed</p>
            <p className="mt-0.5 text-sm font-semibold text-[#323130]">
              {vocab.lastReviewedAt ? fmt(vocab.lastReviewedAt) : 'Not yet'}
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      {vocab.content ? (
        <div className="rounded-xl border border-[#e1dfdd] bg-white px-6 py-5 shadow-sm">
          <p className="mb-3 text-[11px] font-medium uppercase tracking-wide text-[#a19f9d]">
            Definition &amp; notes
          </p>
          <RichTextContent
            html={vocab.content}
            className="text-[15px] leading-relaxed text-[#323130]"
          />
        </div>
      ) : (
        <div className="rounded-xl border border-dashed border-[#e1dfdd] bg-[#faf9f8] px-6 py-8 text-center">
          <p className="text-sm text-[#a19f9d]">No content yet.</p>
          <Link
            href={ROUTES.VOCAB_EDIT(vocab.id)}
            className="mt-1 inline-block text-sm text-[#0078d4] hover:underline"
          >
            Add a definition
          </Link>
        </div>
      )}

      {/* Timeline metadata */}
      <div className="grid grid-cols-2 gap-3">
        <StatCard
          label="Added"
          value={fmt(vocab.createdAt)}
          sub={vocab.createdBy ? `by ${vocab.createdBy}` : undefined}
        />
        {vocab.updatedAt && vocab.updatedAt !== vocab.createdAt ? (
          <StatCard
            label="Last edited"
            value={fmt(vocab.updatedAt)}
            sub={vocab.updatedBy ? `by ${vocab.updatedBy}` : undefined}
          />
        ) : (
          <StatCard label="Last edited" value="—" />
        )}
      </div>
    </div>
  )
}
