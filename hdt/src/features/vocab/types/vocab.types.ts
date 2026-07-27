export type ReviewStage = 0 | 1 | 2 | 3

export interface Vocab {
  id: string
  word: string
  content?: string | null
  notedAt?: string | null
  reviewStage: ReviewStage
  isCompleted: boolean
  nextReviewAt: string | null
  lastReviewedAt: string | null
  createdAt: string
  createdBy?: string
  updatedAt: string
  updatedBy?: string
}

export interface VocabListResponse {
  items: Vocab[]
  pageIndex: number
  pageSize: number
  totalCount: number
  totalPages: number
  hasNextPage: boolean
  hasPreviousPage: boolean
}

export interface CreateVocabPayload {
  word: string
  content?: string
}

export interface UpdateVocabPayload extends Partial<CreateVocabPayload> {
  id: string
}
