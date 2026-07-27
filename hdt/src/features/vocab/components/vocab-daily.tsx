'use client'

import { DataTable } from '@/components/common/data-table'
import { RichTextContent } from '@/components/common/rich-text-content'
import type { ColumnDef } from '@/components/common/data-table'
import { cn } from '@/lib/utils/cn'
import { useDailyVocabs } from '../api/queries'
import { useReviewVocab } from '../api/mutations'
import type { Vocab } from '../types/vocab.types'

const STAGE_BADGE: Record<number, { label: string; cls: string }> = {
  0: { label: 'New',   cls: 'bg-gray-100 text-gray-600' },
  1: { label: 'Day 3', cls: 'bg-blue-100 text-blue-700' },
  2: { label: 'Day 7', cls: 'bg-yellow-100 text-yellow-700' },
  3: { label: 'Done',  cls: 'bg-green-100 text-green-700' },
}

export function VocabDaily() {
  const { data: vocabs = [], isLoading } = useDailyVocabs()
  const { mutate: reviewVocab, isPending, variables: pendingId } = useReviewVocab()

  const columns: ColumnDef<Vocab>[] = [
    {
      key: 'word',
      header: 'Word',
      sortable: true,
      accessor: (row) => (
        <span className="font-semibold text-gray-900">{row.word}</span>
      ),
    },
    {
      key: 'content',
      header: 'Content',
      accessor: (row) => <RichTextContent html={row.content} truncate />,
    },
    {
      key: 'reviewStage',
      header: 'Stage',
      width: '90px',
      align: 'center',
      accessor: (row) => {
        const { label, cls } = STAGE_BADGE[row.reviewStage] ?? STAGE_BADGE[0]
        return (
          <span className={cn('inline-flex rounded-full px-2 py-0.5 text-xs font-medium', cls)}>
            {label}
          </span>
        )
      },
    },
    {
      key: 'action',
      header: '',
      width: '140px',
      align: 'center',
      accessor: (row) =>
        row.isCompleted ? (
          <span className="text-xs font-medium text-green-600">Completed</span>
        ) : (
          <button
            type="button"
            onClick={(e) => { e.stopPropagation(); reviewVocab(row.id) }}
            disabled={isPending && pendingId === row.id}
            className="rounded-md bg-green-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-green-700 disabled:opacity-60"
          >
            {isPending && pendingId === row.id ? 'Saving…' : 'Mark Reviewed'}
          </button>
        ),
    },
  ]

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center gap-3">
        <span className="flex h-8 w-8 items-center justify-center rounded-full bg-orange-100 text-sm font-bold text-orange-600">
          {isLoading ? '…' : vocabs.length}
        </span>
        <p className="text-sm text-gray-600">
          {isLoading ? 'Loading…' : vocabs.length === 1 ? '1 word due today' : `${vocabs.length} words due today`}
        </p>
      </div>

      <DataTable<Vocab>
        columns={columns}
        data={vocabs}
        rowKey="id"
        loading={isLoading}
      />
    </div>
  )
}
