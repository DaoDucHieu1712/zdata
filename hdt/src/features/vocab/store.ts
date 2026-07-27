import { createListStore } from '@/lib/create-list-store'

export interface VocabSearchParams {
  search?: string
  pageIndex?: number
  pageSize?: number
  fromDate?: string  // ISO 8601 UTC
  toDate?: string    // ISO 8601 UTC
}

export const useVocabStore = createListStore<VocabSearchParams>({
  pageIndex: 1,
  pageSize: 10,
})
