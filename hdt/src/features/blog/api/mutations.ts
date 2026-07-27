import { useMutation, useQueryClient } from '@tanstack/react-query'
import { createBlog, updateBlog, deleteBlog } from './fetchers'
import { BLOG_KEYS } from './queries'

export const useCreateBlog = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: createBlog,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: BLOG_KEYS.all }),
  })
}

export const useUpdateBlog = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: updateBlog,
    onSuccess: (updated) => {
      queryClient.invalidateQueries({ queryKey: BLOG_KEYS.all })
      queryClient.setQueryData(BLOG_KEYS.detail(updated.id), updated)
    },
  })
}

export const useDeleteBlog = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: deleteBlog,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: BLOG_KEYS.all }),
  })
}
