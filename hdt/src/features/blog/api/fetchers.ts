import { apiClient } from '@/lib/api-client'
import type { Blog, CreateBlogPayload, UpdateBlogPayload } from '../types/blog.types'
import type { BlogSearchParams } from '../store'

export const fetchBlogs = async (params?: BlogSearchParams): Promise<Blog[]> => {
  const { data } = await apiClient.get('/api/blog', { params })
  return data
}

export const fetchBlogById = async (id: string): Promise<Blog> => {
  const { data } = await apiClient.get(`/api/blog/${id}`)
  return data
}

export const createBlog = async (payload: CreateBlogPayload): Promise<Blog> => {
  const { data } = await apiClient.post('/api/blog', payload)
  return data
}

export const updateBlog = async ({ id, ...payload }: UpdateBlogPayload): Promise<Blog> => {
  const { data } = await apiClient.put(`/api/blog/${id}`, payload)
  return data
}

export const deleteBlog = async (id: string): Promise<void> => {
  await apiClient.delete(`/api/blog/${id}`)
}
