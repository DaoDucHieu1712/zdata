import { apiClient } from '@/lib/api-client'
import type { ApiResponse, PagedResult } from '@/types/api'
import type { Vocab, CreateVocabPayload, UpdateVocabPayload } from '../types/vocab.types'
import type { VocabSearchParams } from '../store'
import type {
  ExamQuestion,
  GenerateExamPayload,
  GradeExamPayload,
  ExamResult,
} from '../types/exam.types'
import type {
  FlashCard,
  FetchFlashcardsParams,
  SubmitFlashcardsPayload,
  SessionResult,
} from '../types/flashcard.types'

export const fetchVocabs = async (params?: VocabSearchParams): Promise<PagedResult<Vocab>> => {
  const { data: envelope } = await apiClient.get<ApiResponse<PagedResult<Vocab>>>('/api/vocab', { params })
  return envelope.data
}

export const fetchDailyVocabs = async (): Promise<Vocab[]> => {
  const { data: envelope } = await apiClient.get<ApiResponse<Vocab[]>>('/api/vocab/daily')
  return envelope.data
}

export const fetchVocabById = async (id: string): Promise<Vocab> => {
  const { data: envelope } = await apiClient.get<ApiResponse<Vocab>>(`/api/vocab/${id}`)
  return envelope.data
}

export const createVocab = async (payload: CreateVocabPayload): Promise<Vocab> => {
  const { data: envelope } = await apiClient.post<ApiResponse<Vocab>>('/api/vocab', payload)
  return envelope.data
}

export const updateVocab = async ({ id, ...payload }: UpdateVocabPayload): Promise<Vocab> => {
  const { data: envelope } = await apiClient.put<ApiResponse<Vocab>>(`/api/vocab/${id}`, payload)
  return envelope.data
}

export const deleteVocab = async (id: string): Promise<void> => {
  await apiClient.delete(`/api/vocab/${id}`)
}

export const reviewVocab = async (id: string): Promise<Vocab> => {
  const { data: envelope } = await apiClient.post<ApiResponse<Vocab>>(`/api/vocab/${id}/review`)
  return envelope.data
}

export const generateExam = async (payload: GenerateExamPayload): Promise<ExamQuestion[]> => {
  const { data: envelope } = await apiClient.post<ApiResponse<ExamQuestion[]>>('/api/vocab/exam/generate', payload)
  return envelope.data
}

export const gradeExam = async (payload: GradeExamPayload): Promise<ExamResult> => {
  const { data: envelope } = await apiClient.post<ApiResponse<ExamResult>>('/api/vocab/exam/grade', payload)
  return envelope.data
}

export const fetchFlashcards = async (params: FetchFlashcardsParams): Promise<FlashCard[]> => {
  const { data: envelope } = await apiClient.get<ApiResponse<FlashCard[]>>('/api/vocab/flashcards', { params })
  return envelope.data
}

export const submitFlashcards = async (payload: SubmitFlashcardsPayload): Promise<SessionResult> => {
  const { data: envelope } = await apiClient.post<ApiResponse<SessionResult>>('/api/vocab/flashcards/submit', payload)
  return envelope.data
}
