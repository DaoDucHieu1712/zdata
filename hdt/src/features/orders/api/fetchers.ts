import { apiClient } from '@/lib/api-client'
import type { Order, CreateOrderPayload } from '../types/order.types'
import type { OrderSearchParams } from '../store'

export const fetchOrders = async (params?: OrderSearchParams): Promise<Order[]> => {
  const { data } = await apiClient.get('/orders', { params })
  return data
}

export const fetchOrderById = async (id: string): Promise<Order> => {
  const { data } = await apiClient.get(`/orders/${id}`)
  return data
}

export const createOrder = async (payload: CreateOrderPayload): Promise<Order> => {
  const { data } = await apiClient.post('/orders', payload)
  return data
}
