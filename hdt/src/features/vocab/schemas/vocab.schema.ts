import { z } from 'zod'

export const vocabSearchSchema = z.object({
  search: z.string().optional(),
  pageIndex: z.number().int().min(1).optional(),
  pageSize: z.number().int().min(1).optional(),
  fromDate: z.string().optional(),
  toDate: z.string().optional(),
})

export type VocabSearchInput = z.infer<typeof vocabSearchSchema>

export const createVocabSchema = z.object({
  word: z.string().min(1, 'Word is required').max(200, 'Max 200 characters'),
  content: z.string().optional(),
})

export type CreateVocabInput = z.infer<typeof createVocabSchema>

export const updateVocabSchema = createVocabSchema.partial()

export type UpdateVocabInput = z.infer<typeof updateVocabSchema>
