'use client'

import { useEffect } from 'react'
import { useForm, Controller } from 'react-hook-form'
import type { SubmitHandler } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'react-toastify'
import { Input } from '@/components/ui/input'
import { RichTextEditor } from '@/components/common/rich-text-editor'
import { createVocabSchema } from '../schemas/vocab.schema'
import type { CreateVocabInput } from '../schemas/vocab.schema'
import { useCreateVocab, useUpdateVocab, useDeleteVocab } from '../api/mutations'
import type { Vocab } from '../types/vocab.types'
import { cn } from '@/lib/utils/cn'

export interface VocabFormProps {
  vocab?: Vocab
  open: boolean
  onClose: () => void
}

const STAGE_INFO: Record<number, { label: string; next: string; color: string }> = {
  0: { label: 'New',    next: 'Review on day 3',  color: 'text-gray-500' },
  1: { label: 'Day 3',  next: 'Review on day 7',  color: 'text-blue-600' },
  2: { label: 'Day 7',  next: 'Review on day 14', color: 'text-yellow-600' },
  3: { label: 'Done',   next: 'Completed',         color: 'text-green-600' },
}

const CONTENT_PLACEHOLDER = `[noun / verb / adj / adv / phrase]
Definition: ...
Example: ...
Notes: ...
Synonyms: ...`

export function VocabForm({ vocab, open, onClose }: VocabFormProps) {
  const isEdit = Boolean(vocab)

  const { mutateAsync: createVocab, isPending: creating } = useCreateVocab()
  const { mutateAsync: updateVocab, isPending: updating } = useUpdateVocab()
  const { mutateAsync: deleteVocab, isPending: deleting } = useDeleteVocab()
  const isPending = creating || updating || deleting

  const {
    register,
    control,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<CreateVocabInput>({
    resolver: zodResolver(createVocabSchema),
  })

  useEffect(() => {
    if (!open) return
    reset(
      vocab
        ? { word: vocab.word, content: vocab.content ?? '' }
        : { word: '', content: '' },
    )
  }, [open, vocab, reset])

  if (!open) return null

  const onSubmit: SubmitHandler<CreateVocabInput> = async (values) => {
    try {
      if (isEdit && vocab) {
        await updateVocab({ id: vocab.id, ...values })
        toast.success(`"${vocab.word}" updated successfully.`)
      } else {
        const created = await createVocab(values)
        toast.success(`"${created?.word ?? 'Word'}" added to your vocab list.`)
      }
      onClose()
    } catch {
      toast.error('Failed to save. Please try again.')
    }
  }

  const handleDelete = async () => {
    if (!vocab) return
    if (!window.confirm(`Delete "${vocab.word}"? This cannot be undone.`)) return
    try {
      await deleteVocab(vocab.id)
      toast.success(`"${vocab.word}" deleted.`)
      onClose()
    } catch {
      toast.error('Failed to delete. Please try again.')
    }
  }

  const stageInfo = vocab ? STAGE_INFO[vocab.reviewStage] : null

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4"
      onClick={onClose}
    >
      <div
        className="w-full max-w-2xl rounded bg-white shadow-[0_8px_32px_rgba(0,0,0,0.18)] border border-[#e1dfdd]"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between border-b border-[#e1dfdd] px-5 py-3.5">
          <div>
            <h2 className="text-[15px] font-semibold text-[#323130]">
              {isEdit ? 'Edit Word' : 'Add New Word'}
            </h2>
            {stageInfo && (
              <p className={cn('mt-0.5 text-[12px]', stageInfo.color)}>
                Stage: {stageInfo.label} — {stageInfo.next}
              </p>
            )}
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded p-1 text-[#605e5c] hover:bg-[#f3f2f1] hover:text-[#323130] transition-colors"
          >
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-3.5 px-5 py-4">
          <Input
            label="Word *"
            placeholder="e.g. ephemeral"
            error={errors.word?.message}
            {...register('word')}
          />

          <Controller
            name="content"
            control={control}
            render={({ field }) => (
              <RichTextEditor
                label="Content"
                placeholder={CONTENT_PLACEHOLDER}
                value={field.value ?? ''}
                onChange={field.onChange}
                error={errors.content?.message}
              />
            )}
          />

          <div className="mt-1 flex items-center justify-between border-t border-[#e1dfdd] pt-3.5">
            <div>
              {isEdit && (
                <button
                  type="button"
                  onClick={handleDelete}
                  disabled={isPending}
                  className="rounded px-3 py-1.5 text-[13px] font-medium text-[#d13438] hover:bg-[#fde7e9] disabled:opacity-50 transition-colors"
                >
                  {deleting ? 'Deleting…' : 'Delete'}
                </button>
              )}
            </div>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={onClose}
                disabled={isPending}
                className="rounded border border-[#e1dfdd] px-4 py-1.5 text-[13px] font-medium text-[#323130] hover:bg-[#f3f2f1] disabled:opacity-50 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isPending}
                className="rounded bg-[#0078d4] px-4 py-1.5 text-[13px] font-medium text-white hover:bg-[#106ebe] disabled:opacity-60 transition-colors"
              >
                {creating || updating ? 'Saving…' : isEdit ? 'Save Changes' : 'Add Word'}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  )
}
