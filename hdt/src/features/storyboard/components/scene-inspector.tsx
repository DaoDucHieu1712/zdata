'use client'

import { useEffect } from 'react'
import { Controller, useForm, useWatch } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Select } from '@/components/ui/select'
import { useStoryboardStore } from '../store'
import { sceneSchema, type SceneInput } from '../schemas/scene.schema'
import { MEDIA_MODES, VIDEO_MAX_DURATION } from '../config/storyboard-config'
import type { SceneNode } from '../types/storyboard.types'

/**
 * Right rail form for the selected scene. Built with React Hook Form + Zod and
 * auto-saves valid changes back into the store on every edit (SRS FR-SB-03).
 */
export function SceneInspector() {
  const selectedId = useStoryboardStore((s) => s.selectedId)
  const scene = useStoryboardStore(
    (s) => s.nodes.find((n) => n.id === s.selectedId && n.data.kind === 'scene') as SceneNode | undefined,
  )
  const updateScene = useStoryboardStore((s) => s.updateScene)
  const removeNode = useStoryboardStore((s) => s.removeNode)

  const { control, register, reset, formState: { errors } } = useForm<SceneInput>({
    resolver: zodResolver(sceneSchema),
    mode: 'onChange',
  })

  const values = useWatch({ control })
  const mediaMode = values.mediaMode

  // Load the selected scene into the form when selection changes.
  useEffect(() => {
    if (!scene) return
    reset({
      title: scene.data.title,
      prompt: scene.data.prompt,
      cameraNote: scene.data.cameraNote,
      mediaMode: scene.data.mediaMode,
      durationSec: scene.data.durationSec,
      dialogue: scene.data.dialogue,
    })
  }, [scene?.id, reset]) // eslint-disable-line react-hooks/exhaustive-deps

  // Push edits back to the store as the user types.
  useEffect(() => {
    if (!selectedId || values.title === undefined) return
    updateScene(selectedId, {
      title: values.title,
      prompt: values.prompt,
      cameraNote: values.cameraNote ?? '',
      mediaMode: values.mediaMode,
      durationSec: values.durationSec,
      dialogue: values.dialogue ?? '',
    })
  }, [selectedId, values, updateScene])

  if (!scene) {
    return (
      <aside className="flex w-80 shrink-0 items-center justify-center border-l border-[#e1dfdd] bg-[#faf9f8] p-4">
        <p className="text-center text-[12.5px] text-[#a19f9d]">Select a scene to edit its prompt and settings.</p>
      </aside>
    )
  }

  return (
    <aside className="flex w-80 shrink-0 flex-col overflow-y-auto border-l border-[#e1dfdd] bg-[#faf9f8]">
      <header className="flex items-center gap-2 border-b border-[#e1dfdd] px-4 py-3">
        <span className="flex h-6 w-6 items-center justify-center rounded-full bg-[#0078d4] text-[12px] font-bold text-white">
          {scene.data.order}
        </span>
        <span className="text-[13px] font-semibold text-[#201f1e]">Scene settings</span>
      </header>

      <form className="flex flex-col gap-3.5 p-4">
        <Input label="Title" error={errors.title?.message} {...register('title')} />

        <Textarea
          label="Prompt (image description)"
          rows={4}
          placeholder="Describe the shot: subject, setting, lighting, mood…"
          error={errors.prompt?.message}
          {...register('prompt')}
        />

        <Controller
          control={control}
          name="mediaMode"
          render={({ field }) => (
            <Select
              label="Media mode"
              options={MEDIA_MODES}
              value={field.value}
              onChange={field.onChange}
              onBlur={field.onBlur}
              error={errors.mediaMode?.message}
            />
          )}
        />

        {mediaMode === 'video' && (
          <Input
            label="Camera note"
            placeholder="e.g. slow pan left, push-in…"
            error={errors.cameraNote?.message}
            {...register('cameraNote')}
          />
        )}

        <Input
          label="Duration (seconds)"
          type="number"
          min={1}
          max={60}
          hint={mediaMode === 'video' ? `Video clips are clamped to ${VIDEO_MAX_DURATION}s max on export.` : undefined}
          error={errors.durationSec?.message}
          {...register('durationSec', { valueAsNumber: true })}
        />

        <Textarea
          label="Dialogue / narration"
          rows={3}
          placeholder="Optional line for text-to-speech…"
          error={errors.dialogue?.message}
          {...register('dialogue')}
        />

        {scene.data.error && (
          <p className="rounded bg-red-50 px-2 py-1.5 text-[11.5px] text-red-600">{scene.data.error}</p>
        )}

        <button
          type="button"
          onClick={() => removeNode(scene.id)}
          className="mt-1 rounded border border-red-200 px-3 py-1.5 text-[12.5px] font-medium text-red-600 transition-colors hover:bg-red-50"
        >
          Delete scene
        </button>
      </form>
    </aside>
  )
}
