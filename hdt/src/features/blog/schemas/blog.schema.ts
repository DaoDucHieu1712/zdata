import { z } from 'zod'

export const blogSearchSchema = z.object({
  title: z.string().optional(),
  author: z.string().optional(),
  status: z.enum(['', 'draft', 'published', 'archived']).optional(),
  tags: z.array(z.string()).optional(),
  dateFrom: z.string().optional(),
  dateTo: z.string().optional(),
})

export type BlogSearchInput = z.infer<typeof blogSearchSchema>

export const createBlogSchema = z.object({
  title: z.string().min(1, 'Title is required').max(200, 'Max 200 characters'),
  excerpt: z.string().max(500, 'Max 500 characters').optional(),
  content: z.string().min(1, 'Content is required'),
  author: z.string().min(1, 'Author is required'),
  status: z.enum(['draft', 'published']),
  tags: z.array(z.string()).default([]),
})

export type CreateBlogInput = z.infer<typeof createBlogSchema>
