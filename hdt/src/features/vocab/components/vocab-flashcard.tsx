'use client'

import { useCallback } from 'react'
import { useFlashcardStore } from '../flashcard-store'
import { useGetFlashcards, useSubmitFlashcards } from '../api/mutations'
import { VocabFlashcardConfig } from './vocab-flashcard-config'
import { VocabFlashcardCard } from './vocab-flashcard-card'
import { VocabFlashcardSummary } from './vocab-flashcard-summary'

function Spinner({ text }: { text: string }) {
  return (
    <div className="flex flex-col items-center gap-3 py-20">
      <svg className="h-8 w-8 animate-spin text-[#0078d4]" fill="none" viewBox="0 0 24 24">
        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
      </svg>
      <p className="text-sm text-[#605e5c]">{text}</p>
    </div>
  )
}

export function VocabFlashcard() {
  const {
    phase,
    count,
    reviewStage,
    useDaily,
    setPhase,
    startSession,
    answer,
    setSessionResult,
  } = useFlashcardStore()

  const getDeckMutation    = useGetFlashcards()
  const submitMutation     = useSubmitFlashcards()

  const handleStart = useCallback(async () => {
    setPhase('loading')
    try {
      const deck = await getDeckMutation.mutateAsync({ count, reviewStage, useDaily })
      if (!deck || deck.length === 0) {
        setPhase('config')
        return
      }
      startSession(deck)
    } catch {
      setPhase('config')
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [count, reviewStage, useDaily])

  const handleAnswer = useCallback(async (knew: boolean) => {
    answer(knew)
    const s = useFlashcardStore.getState()
    if (s.currentIndex >= s.deck.length) {
      setPhase('submitting')
      try {
        const result = await submitMutation.mutateAsync({ results: s.results })
        setSessionResult(result)
      } catch {
        setPhase('playing')
      }
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [answer, setPhase, setSessionResult])

  const startError =
    getDeckMutation.isError
      ? 'Failed to load cards. Please try again.'
      : getDeckMutation.data?.length === 0
      ? 'No cards found with these filters. Try changing your selection.'
      : null

  if (phase === 'loading')    return <Spinner text="Loading cards…" />
  if (phase === 'submitting') return <Spinner text="Saving results…" />
  if (phase === 'playing')    return <VocabFlashcardCard onAnswer={handleAnswer} />
  if (phase === 'summary')    return <VocabFlashcardSummary />
  return <VocabFlashcardConfig onStart={handleStart} error={startError} />
}
