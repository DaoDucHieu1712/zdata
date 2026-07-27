export interface FlashCard {
  vocabId: string
  word: string
  content?: string | null
  reviewStage: number
}

export interface CardResult {
  vocabId: string
  knew: boolean
}

export interface SubmitFlashcardsPayload {
  results: CardResult[]
}

export interface SessionResult {
  totalCards: number
  knewCount: number
  didntKnowCount: number
}

export interface FetchFlashcardsParams {
  count?: number
  reviewStage?: number | null
  useDaily?: boolean
}

export type FlashcardPhase = 'config' | 'loading' | 'playing' | 'submitting' | 'summary'
