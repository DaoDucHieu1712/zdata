import { useQuery } from '@tanstack/react-query'
import { createQueryKeys } from '@/lib/create-query-keys'
import { fetchOrders, fetchOrderById } from './fetchers'
import type { OrderSearchParams } from '../store'

export const ORDER_KEYS = createQueryKeys<OrderSearchParams>('orders')

export const useOrders = (params?: OrderSearchParams) =>
  useQuery({
    queryKey: ORDER_KEYS.list(params),
    queryFn: () => fetchOrders(params),
  })

export const useOrderById = (id: string) =>
  useQuery({
    queryKey: ORDER_KEYS.detail(id),
    queryFn: () => fetchOrderById(id),
    enabled: !!id,
  })
