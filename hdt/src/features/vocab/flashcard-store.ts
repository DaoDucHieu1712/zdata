import { create } from 'zustand'
import type { FlashCard, CardResult, SessionResult, FlashcardPhase } from './types/flashcard.types'

interface FlashcardState {
  phase: FlashcardPhase
  // config
  count: number
  reviewStage: number | null
  useDaily: boolean
  // session
  deck: FlashCard[]
  currentIndex: number
  isFlipped: boolean
  results: CardResult[]
  sessionResult: SessionResult | null
  // actions
  setConfig: (patch: Partial<{ count: number; reviewStage: number | null; useDaily: boolean }>) => void
  setPhase: (phase: FlashcardPhase) => void
  startSession: (deck: FlashCard[]) => void
  flip: () => void
  answer: (knew: boolean) => void
  setSessionResult: (result: SessionResult) => void
  reset: () => void
}

const DEFAULT: Pick<FlashcardState,
  'phase' | 'count' | 'reviewStage' | 'useDaily' |
  'deck' | 'currentIndex' | 'isFlipped' | 'results' | 'sessionResult'
> = {
  phase: 'config',
  count: 10,
  reviewStage: null,
  useDaily: false,
  deck: [],
  currentIndex: 0,
  isFlipped: false,
  results: [],
  sessionResult: null,
}

export const useFlashcardStore = create<FlashcardState>((set) => ({
  ...DEFAULT,

  setConfig: (patch) => set((s) => ({ ...s, ...patch })),

  setPhase: (phase) => set({ phase }),

  startSession: (deck) => set({
    deck,
    currentIndex: 0,
    isFlipped: false,
    results: [],
    sessionResult: null,
    phase: 'playing',
  }),

  flip: () => set((s) => ({ isFlipped: !s.isFlipped })),

  answer: (knew) => set((s) => {
    const card = s.deck[s.currentIndex]
    if (!card) return s
    return {
      results: [...s.results, { vocabId: card.vocabId, knew }],
      currentIndex: s.currentIndex + 1,
      isFlipped: false,
    }
  }),

  setSessionResult: (sessionResult) => set({ sessionResult, phase: 'summary' }),

  reset: () => set(DEFAULT),
}))
