import { useMutation, useQueryClient } from '@tanstack/react-query'
import { createVocab, updateVocab, deleteVocab, reviewVocab, generateExam, gradeExam, fetchFlashcards, submitFlashcards } from './fetchers'
import { VOCAB_KEYS } from './queries'

export const useCreateVocab = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: createVocab,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: VOCAB_KEYS.all }),
  })
}

export const useUpdateVocab = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: updateVocab,
    onSuccess: (updated) => {
      queryClient.invalidateQueries({ queryKey: VOCAB_KEYS.all })
      // Guard: some API implementations return null for data on PUT responses
      if (updated?.id) {
        queryClient.setQueryData(VOCAB_KEYS.detail(updated.id), updated)
      }
    },
  })
}

export const useDeleteVocab = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: deleteVocab,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: VOCAB_KEYS.all }),
  })
}

export const useReviewVocab = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: reviewVocab,
    onSuccess: (updated) => {
      queryClient.invalidateQueries({ queryKey: VOCAB_KEYS.all })
      queryClient.invalidateQueries({ queryKey: VOCAB_KEYS.daily })
      if (updated?.id) {
        queryClient.setQueryData(VOCAB_KEYS.detail(updated.id), updated)
      }
    },
  })
}

export const useGenerateExam = () =>
  useMutation({ mutationFn: generateExam })

export const useGradeExam = () =>
  useMutation({ mutationFn: gradeExam })

export const useGetFlashcards = () =>
  useMutation({ mutationFn: fetchFlashcards })

export const useSubmitFlashcards = () =>
  useMutation({ mutationFn: submitFlashcards })
