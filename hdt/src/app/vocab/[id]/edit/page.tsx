'use client'

import { use } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { VocabFormCard } from '@/features/vocab/components/vocab-form-card'
import { useVocabById } from '@/features/vocab'
import { ROUTES } from '@/config/routes'

interface Props {
  params: Promise<{ id: string }>
}

export default function VocabEditPage({ params }: Props) {
  const { id } = use(params)
  const router = useRouter()
  const { data: vocab, isLoading, isError } = useVocabById(id)

  if (isLoading) {
    return (
      <div className="flex items-center gap-3 py-10 text-sm text-[#605e5c]">
        <div className="h-4 w-4 animate-spin rounded-full border-2 border-[#e1dfdd] border-t-[#0078d4]" />
        Loading…
      </div>
    )
  }

  if (isError || !vocab) {
    return (
      <div className="flex flex-col gap-3 py-10">
        <p className="text-sm text-[#d13438]">Could not load this vocab entry.</p>
        <Link href={ROUTES.VOCAB} className="text-sm text-[#0078d4] hover:underline">
          ← Back to Vocabulary
        </Link>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-5 max-w-2xl">
      {/* Breadcrumb */}
      <div className="flex items-center gap-2 text-sm text-[#605e5c]">
        <Link href={ROUTES.VOCAB} className="hover:text-[#0078d4] transition-colors">
          Vocabulary
        </Link>
        <span>/</span>
        <Link
          href={ROUTES.VOCAB_DETAIL(id)}
          className="hover:text-[#0078d4] transition-colors"
        >
          {vocab.word}
        </Link>
        <span>/</span>
        <span className="text-[#323130]">Edit</span>
      </div>

      <VocabFormCard
        vocab={vocab}
        onSuccess={(id) => router.push(ROUTES.VOCAB_DETAIL(id))}
        onCancel={() => router.push(ROUTES.VOCAB_DETAIL(id))}
      />
    </div>
  )
}
