import { z } from 'zod'

export const generateExamSchema = z
  .object({
    questionCount: z
      .number({ error: 'Must be a number' })
      .int()
      .min(1, 'At least 1 question')
      .max(50, 'Maximum 50 questions'),
    from: z.string().nullable().optional(),
    to: z.string().nullable().optional(),
  })
  .refine(
    (d) => {
      if (d.from && d.to) return new Date(d.from) <= new Date(d.to)
      return true
    },
    { message: '"From" must be on or before "To"', path: ['to'] },
  )

export type GenerateExamInput = z.infer<typeof generateExamSchema>
