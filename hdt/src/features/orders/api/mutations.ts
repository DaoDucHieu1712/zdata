import { useMutation, useQueryClient } from '@tanstack/react-query'
import { createOrder } from './fetchers'
import { ORDER_KEYS } from './queries'

export const useCreateOrder = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: createOrder,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ORDER_KEYS.all }),
  })
}
