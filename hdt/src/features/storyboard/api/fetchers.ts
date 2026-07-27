import { apiClient } from '@/lib/api-client'
import { USE_MOCK_FALLBACK } from '../config/storyboard-config'
import {
  mockAutoBreakdown,
  mockGenerateAudio,
  mockGenerateImage,
  mockGenerateVideo,
  mockRenderVideo,
} from './mock'
import type {
  AutoBreakdownRequest,
  AutoBreakdownResponse,
  GenerateAudioRequest,
  GenerateAudioResponse,
  GenerateImageRequest,
  GenerateImageResponse,
  GenerateVideoRequest,
  GenerateVideoResponse,
  RenderVideoRequest,
  RenderVideoResponse,
} from '../types/storyboard.types'

/**
 * Run a real Cloud AI call, falling back to a local mock when the backend is
 * unreachable and USE_MOCK_FALLBACK is on. This keeps the wiring identical to
 * production while letting the demo work with no server.
 */
async function withMock<T>(real: () => Promise<T>, mock: () => Promise<T>): Promise<T> {
  if (!USE_MOCK_FALLBACK) return real()
  try {
    return await real()
  } catch {
    return mock()
  }
}

/** Text → image. POST /ai/images/generate */
export const generateImage = (req: GenerateImageRequest): Promise<GenerateImageResponse> =>
  withMock(
    async () => {
      const { data } = await apiClient.post<GenerateImageResponse>('/ai/images/generate', req)
      return data
    },
    () => mockGenerateImage(req.prompt),
  )

/** Image → video. POST /ai/videos/generate */
export const generateVideo = (req: GenerateVideoRequest): Promise<GenerateVideoResponse> =>
  withMock(
    async () => {
      const { data } = await apiClient.post<GenerateVideoResponse>('/ai/videos/generate', req)
      return data
    },
    () => mockGenerateVideo(req.imageUrl, req.durationSec),
  )

/** Text → speech (TTS). POST /ai/audio/generate */
export const generateAudio = (req: GenerateAudioRequest): Promise<GenerateAudioResponse> =>
  withMock(
    async () => {
      const { data } = await apiClient.post<GenerateAudioResponse>('/ai/audio/generate', req)
      return data
    },
    () => mockGenerateAudio(req.text, req.speed),
  )

/** Script → scene list. POST /ai/script/breakdown */
export const autoBreakdown = (req: AutoBreakdownRequest): Promise<AutoBreakdownResponse> =>
  withMock(
    async () => {
      const { data } = await apiClient.post<AutoBreakdownResponse>('/ai/script/breakdown', req)
      return data
    },
    () => mockAutoBreakdown(req.scriptText, req.projectType),
  )

/** Stitch scene clips into a final video. POST /ai/videos/render */
export const renderVideo = (req: RenderVideoRequest): Promise<RenderVideoResponse> =>
  withMock(
    async () => {
      const { data } = await apiClient.post<RenderVideoResponse>('/ai/videos/render', req)
      return data
    },
    () => mockRenderVideo(req.clips),
  )
