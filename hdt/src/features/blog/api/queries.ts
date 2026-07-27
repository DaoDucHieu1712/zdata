import { useQuery } from '@tanstack/react-query'
import { createQueryKeys } from '@/lib/create-query-keys'
import { fetchBlogs, fetchBlogById } from './fetchers'
import type { BlogSearchParams } from '../store'

export const BLOG_KEYS = createQueryKeys<BlogSearchParams>('blogs')

export const useBlogs = (params?: BlogSearchParams) =>
  useQuery({
    queryKey: BLOG_KEYS.list(params),
    queryFn: () => fetchBlogs(params),
  })

export const useBlogById = (id: string) =>
  useQuery({
    queryKey: BLOG_KEYS.detail(id),
    queryFn: () => fetchBlogById(id),
    enabled: !!id,
  })
