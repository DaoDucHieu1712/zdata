import { createListStore } from '@/lib/create-list-store'

export interface OrderSearchParams {
  status?: 'pending' | 'confirmed' | 'shipped' | 'delivered' | ''
  userId?: string
  dateFrom?: string
  dateTo?: string
}

export const useOrdersStore = createListStore<OrderSearchParams>({})
