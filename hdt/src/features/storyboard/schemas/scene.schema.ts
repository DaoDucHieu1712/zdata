import { z } from 'zod'

/** Editable scene fields (SRS FR-SB-03). Asset/status fields live in the store. */
export const sceneSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  prompt: z.string().min(3, 'Describe the shot (min 3 characters)'),
  cameraNote: z.string().optional(),
  mediaMode: z.enum(['video', 'image']),
  durationSec: z.number().int().min(1).max(60),
  dialogue: z.string().optional(),
})

export type SceneInput = z.infer<typeof sceneSchema>
