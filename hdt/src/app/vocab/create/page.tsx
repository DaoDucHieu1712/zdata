'use client'

import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { VocabFormCard } from '@/features/vocab/components/vocab-form-card'
import { ROUTES } from '@/config/routes'

export default function VocabCreatePage() {
  const router = useRouter()

  return (
    <div className="flex flex-col gap-5 max-w-2xl">
      {/* Breadcrumb */}
      <div className="flex items-center gap-2 text-sm text-[#605e5c]">
        <Link href={ROUTES.VOCAB} className="hover:text-[#0078d4] transition-colors">
          Vocabulary
        </Link>
        <span>/</span>
        <span className="text-[#323130]">New Word</span>
      </div>

      <VocabFormCard
        onSuccess={() => {}}
        onCancel={() => router.push(ROUTES.VOCAB)}
      />
    </div>
  )
}
