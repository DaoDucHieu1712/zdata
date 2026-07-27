'use client'

import { useEffect } from 'react'
import type { ReactNode } from 'react'
import { useRouter } from 'next/navigation'
import { DataTable } from '@/components/common/data-table'
import { SearchPanel } from '@/components/common/search-panel'
import { RichTextContent } from '@/components/common/rich-text-content'
import type { ColumnDef } from '@/components/common/data-table'
import type { SearchFieldConfig } from '@/components/common/search-panel'
import { cn } from '@/lib/utils/cn'
import { ROUTES } from '@/config/routes'
import { useVocabStore } from '../store'
import { useVocabs } from '../api/queries'
import { vocabSearchSchema } from '../schemas/vocab.schema'
import type { Vocab } from '../types/vocab.types'
import type { VocabSearchInput } from '../schemas/vocab.schema'

// ── Stage display ──────────────────────────────────────────────────────────────

const STAGE_BADGE: Record<number, { label: string; cls: string }> = {
  0: { label: 'New',   cls: 'bg-[#f3f2f1] text-[#605e5c]' },
  1: { label: 'Day 3', cls: 'bg-[#deecf9] text-[#0078d4]' },
  2: { label: 'Day 7', cls: 'bg-[#fff4ce] text-[#8a6c00]' },
  3: { label: 'Done',  cls: 'bg-[#dff6dd] text-[#107c10]' },
}

function StageBadge({ stage }: { stage: number }): ReactNode {
  const { label, cls } = STAGE_BADGE[stage] ?? STAGE_BADGE[0]
  return (
    <span className={cn('inline-flex rounded-full px-2 py-0.5 text-xs font-medium', cls)}>
      {label}
    </span>
  )
}

// ── Search fields ──────────────────────────────────────────────────────────────

const SEARCH_FIELDS: SearchFieldConfig[] = [
  { type: 'text', name: 'search',   label: 'Search',     placeholder: 'Search by word…' },
  { type: 'date', name: 'fromDate', label: 'Added from' },
  { type: 'date', name: 'toDate',   label: 'Added to' },
]

const DEFAULT_SEARCH: VocabSearchInput = { search: '', fromDate: '', toDate: '' }

// ── Component ──────────────────────────────────────────────────────────────────

export function VocabList() {
  const router = useRouter()
  const { searchParams, pagination, setSearchParams, setPagination } = useVocabStore()

  const { data: response, isLoading } = useVocabs({
    search: searchParams.search,
    fromDate: searchParams.fromDate,
    toDate: searchParams.toDate,
    pageIndex: pagination.page,
    pageSize: pagination.pageSize,
  })

  useEffect(() => {
    if (response?.totalCount !== undefined) {
      setPagination({ total: response.totalCount })
    }
  }, [response?.totalCount, setPagination])

  const rows = response?.items ?? []

  const columns: ColumnDef<Vocab>[] = [
    {
      key: 'word',
      header: 'Word',
      accessor: 'word',
      sortable: true,
      render: (row) => (
        <span className="font-medium text-[#323130]">{row.word}</span>
      ),
    },
    {
      key: 'content',
      header: 'Content',
      accessor: 'content',
      render: (row) => <RichTextContent html={row.content} truncate />,
    },
    {
      key: 'reviewStage',
      header: 'Stage',
      width: '90px',
      align: 'center',
      accessor: 'reviewStage',
      render: (row) => <StageBadge stage={row.reviewStage} />,
    },
    {
      key: 'nextReviewAt',
      header: 'Next Review',
      width: '130px',
      align: 'right',
      accessor: 'nextReviewAt',
      render: (row) =>
        row.isCompleted
          ? <span className="text-xs text-green-600">Completed</span>
          : row.nextReviewAt
          ? <span className="text-xs">{new Date(row.nextReviewAt).toLocaleDateString()}</span>
          : <span className="text-gray-300">—</span>,
    },
    {
      key: 'createdAt',
      header: 'Created',
      width: '100px',
      align: 'right',
      accessor: 'createdAt',
      sortable: true,
      render: (row) => (
        <span className="text-xs text-gray-500">
          {new Date(row.createdAt).toLocaleDateString()}
        </span>
      ),
    },
    {
      key: 'actions',
      header: '',
      width: '60px',
      align: 'center',
      render: (row) => (
        <button
          onClick={(e) => { e.stopPropagation(); router.push(ROUTES.VOCAB_EDIT(row.id)) }}
          className="rounded px-2 py-1 text-xs text-[#0078d4] opacity-0 group-hover:opacity-100 transition-opacity hover:bg-[#deecf9]"
        >
          Edit
        </button>
      ),
    },
  ]

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <p className="text-[13px] text-[#605e5c]">
          {response?.totalCount ?? 0} words total
        </p>
        <button
          onClick={() => router.push(ROUTES.VOCAB_CREATE)}
          className="rounded px-3 py-1.5 text-[13px] font-medium text-white bg-[#0078d4] hover:bg-[#106ebe] transition-colors"
        >
          + Add Word
        </button>
      </div>

      <SearchPanel<VocabSearchInput>
        fields={SEARCH_FIELDS}
        schema={vocabSearchSchema}
        defaultValues={DEFAULT_SEARCH}
        cols={3}
        loading={isLoading}
        onSearch={(values) => setSearchParams({
          search: values.search,
          fromDate: values.fromDate ? `${values.fromDate}T00:00:00Z` : undefined,
          toDate:   values.toDate   ? `${values.toDate}T23:59:59Z`   : undefined,
        })}
        onReset={() => setSearchParams({})}
      />

      <DataTable<Vocab>
        columns={columns}
        data={rows}
        rowKey="id"
        loading={isLoading}
        pagination={pagination}
        onRowClick={(row) => router.push(ROUTES.VOCAB_DETAIL(row.id))}
        onPageChange={(page, pageSize) => setPagination({ page, pageSize })}
      />
    </div>
  )
}
