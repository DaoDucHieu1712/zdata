import { z } from 'zod'

const optionalIntField = (min: number, max: number) =>
  z.preprocess(
    (v) => (v === '' || v === null || v === undefined ? null : Number(v)),
    z.number().int().min(min).max(max).nullable().optional(),
  )

export const flashcardConfigSchema = z.object({
  count: z.number().int().min(1).max(100).optional(),
  reviewStage: optionalIntField(0, 3),
  useDaily: z.boolean().optional(),
})

export type FlashcardConfigInput = z.infer<typeof flashcardConfigSchema>
