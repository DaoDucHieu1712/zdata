import { useQuery } from '@tanstack/react-query'
import { createQueryKeys } from '@/lib/create-query-keys'
import { fetchVocabs, fetchDailyVocabs, fetchVocabById } from './fetchers'
import type { VocabSearchParams } from '../store'

export const VOCAB_KEYS = {
  ...createQueryKeys<VocabSearchParams>('vocabs'),
  daily: ['vocabs', 'daily'] as const,
}

export const useVocabs = (params?: VocabSearchParams) =>
  useQuery({
    queryKey: VOCAB_KEYS.list(params),
    queryFn: () => fetchVocabs(params),
  })

export const useDailyVocabs = () =>
  useQuery({
    queryKey: VOCAB_KEYS.daily,
    queryFn: fetchDailyVocabs,
  })

export const useVocabById = (id: string) =>
  useQuery({
    queryKey: VOCAB_KEYS.detail(id),
    queryFn: () => fetchVocabById(id),
    enabled: !!id,
  })
