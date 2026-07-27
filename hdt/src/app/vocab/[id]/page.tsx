'use client'

import { use } from 'react'
import Link from 'next/link'
import { VocabDetail } from '@/features/vocab/components/vocab-detail'
import { useVocabById } from '@/features/vocab'
import { ROUTES } from '@/config/routes'

interface Props {
  params: Promise<{ id: string }>
}

export default function VocabDetailPage({ params }: Props) {
  const { id } = use(params)
  const { data: vocab, isLoading, isError } = useVocabById(id)

  if (isLoading) {
    return (
      <div className="flex flex-col gap-5 max-w-3xl animate-pulse">
        <div className="rounded-xl border border-[#e1dfdd] bg-white shadow-sm overflow-hidden">
          <div className="px-6 pt-6 pb-4 flex items-start justify-between">
            <div className="flex flex-col gap-3">
              <div className="h-9 w-48 rounded bg-[#f3f2f1]" />
              <div className="h-3 w-40 rounded bg-[#f3f2f1]" />
            </div>
            <div className="h-9 w-16 rounded-lg bg-[#f3f2f1]" />
          </div>
          <div className="border-t border-[#f3f2f1] grid grid-cols-3 divide-x divide-[#f3f2f1]">
            {[0, 1, 2].map((i) => (
              <div key={i} className="px-5 py-3 flex flex-col gap-1.5">
                <div className="h-2.5 w-14 rounded bg-[#f3f2f1]" />
                <div className="h-3.5 w-20 rounded bg-[#f3f2f1]" />
              </div>
            ))}
          </div>
        </div>
        <div className="rounded-xl border border-[#e1dfdd] bg-white px-6 py-5 shadow-sm flex flex-col gap-2">
          <div className="h-2.5 w-24 rounded bg-[#f3f2f1]" />
          <div className="h-4 w-full rounded bg-[#f3f2f1]" />
          <div className="h-4 w-5/6 rounded bg-[#f3f2f1]" />
          <div className="h-4 w-4/6 rounded bg-[#f3f2f1]" />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div className="h-16 rounded-lg border border-[#e1dfdd] bg-white" />
          <div className="h-16 rounded-lg border border-[#e1dfdd] bg-white" />
        </div>
      </div>
    )
  }

  if (isError || !vocab) {
    return (
      <div className="flex flex-col items-start gap-3 rounded-xl border border-[#fde7e9] bg-[#fff4f4] px-6 py-8 max-w-md">
        <p className="text-sm font-medium text-[#d13438]">Could not load this vocab entry.</p>
        <Link href={ROUTES.VOCAB} className="text-sm text-[#0078d4] hover:underline">
          ← Back to Vocabulary
        </Link>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-5">
      {/* Breadcrumb */}
      <div className="flex items-center gap-2 text-sm text-[#605e5c]">
        <Link href={ROUTES.VOCAB} className="hover:text-[#0078d4] transition-colors">
          Vocabulary
        </Link>
        <span>/</span>
        <span className="text-[#323130]">{vocab.word}</span>
      </div>

      <VocabDetail vocab={vocab} />
    </div>
  )
}
