import { useMutation } from '@tanstack/react-query'
import {
  autoBreakdown,
  generateAudio,
  generateImage,
  generateVideo,
  renderVideo,
} from './fetchers'

/** Text → image generation. */
export const useGenerateImage = () => useMutation({ mutationFn: generateImage })

/** Image → video clip generation. */
export const useGenerateVideo = () => useMutation({ mutationFn: generateVideo })

/** Text → speech (TTS) generation (FR-VA). */
export const useGenerateAudio = () => useMutation({ mutationFn: generateAudio })

/** Script → auto scene breakdown (FR-SB-04). */
export const useAutoBreakdown = () => useMutation({ mutationFn: autoBreakdown })

/** Stitch all scene clips into the final video. */
export const useRenderVideo = () => useMutation({ mutationFn: renderVideo })
