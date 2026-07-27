export type QuestionType = 0 | 1 | 2

export interface ExamQuestion {
  questionId: string
  vocabId: string
  type: QuestionType
  word: string
  displayedContent: string | null
  options: string[] | null
}

export interface GenerateExamPayload {
  questionCount: number
  from?: string | null
  to?: string | null
}

export interface SubmitAnswerItem {
  questionId: string
  vocabId: string
  type: QuestionType
  displayedContent: string | null
  answer: string
}

export interface GradeExamPayload {
  answers: SubmitAnswerItem[]
}

export interface AnswerResult {
  questionId: string
  word: string
  correctAnswer: string
  submittedAnswer: string
  isCorrect: boolean
}

export interface ExamResult {
  totalQuestions: number
  correctCount: number
  score: number
  results: AnswerResult[]
}

export interface UserAnswer {
  questionId: string
  vocabId: string
  type: QuestionType
  displayedContent: string | null
  answer: string
}

export type ExamPhase = 'idle' | 'loading' | 'in-progress' | 'submitting' | 'result'
