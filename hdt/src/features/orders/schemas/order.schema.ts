import { z } from 'zod'

export const createOrderSchema = z.object({
  items: z.array(
    z.object({
      productId: z.string().uuid(),
      quantity: z.number().int().min(1),
    }),
  ).min(1, 'At least one item required'),
})

export type CreateOrderInput = z.infer<typeof createOrderSchema>
