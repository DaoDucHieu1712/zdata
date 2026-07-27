import { create } from 'zustand'
import type { ExamQuestion, UserAnswer, ExamResult, ExamPhase } from './types/exam.types'

interface ExamConfig {
  questionCount: number
  from: string        // YYYY-MM-DD, "" = unset
  to: string          // YYYY-MM-DD, "" = unset
}

interface ExamState extends ExamConfig {
  phase: ExamPhase
  questions: ExamQuestion[]
  answers: Record<string, UserAnswer>
  result: ExamResult | null

  setConfig: (patch: Partial<ExamConfig>) => void
  setPhase: (phase: ExamPhase) => void
  initAnswers: (questions: ExamQuestion[]) => void
  setAnswer: (questionId: string, answer: string) => void
  setResult: (result: ExamResult) => void
  reset: () => void
}

const INITIAL_STATE = {
  phase: 'idle' as ExamPhase,
  questionCount: 10,
  from: '',
  to: '',
  questions: [] as ExamQuestion[],
  answers: {} as Record<string, UserAnswer>,
  result: null as ExamResult | null,
}

export const useExamStore = create<ExamState>((set) => ({
  ...INITIAL_STATE,

  setConfig: (patch) => set((s) => ({ ...s, ...patch })),

  setPhase: (phase) => set({ phase }),

  initAnswers: (questions) => {
    const answers: Record<string, UserAnswer> = {}
    for (const q of questions) {
      answers[q.questionId] = {
        questionId: q.questionId,
        vocabId: q.vocabId,
        type: q.type,
        displayedContent: q.displayedContent,
        answer: '',
      }
    }
    set({ questions, answers, phase: 'in-progress' })
  },

  setAnswer: (questionId, answer) =>
    set((state) => ({
      answers: {
        ...state.answers,
        [questionId]: { ...state.answers[questionId], answer },
      },
    })),

  setResult: (result) => set({ result, phase: 'result' }),

  reset: () => set(INITIAL_STATE),
}))
