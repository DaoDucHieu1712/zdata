import { createListStore } from '@/lib/create-list-store'

export interface BlogSearchParams {
  title?: string
  author?: string
  status?: 'draft' | 'published' | 'archived' | ''
  tags?: string[]
  dateFrom?: string
  dateTo?: string
}

export const useBlogStore = createListStore<BlogSearchParams>({})
