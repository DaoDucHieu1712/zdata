'use client'

import { memo, useRef } from 'react'
import { Handle, Position, type NodeProps } from '@xyflow/react'
import { cn } from '@/lib/utils/cn'
import { useStoryboardStore } from '../store'
import { UPLOAD_ACCEPT } from '../config/storyboard-config'
import type { AssetStatus, SceneNode as SceneNodeType, SceneStatus } from '../types/storyboard.types'

const SCENE_STATUS_META: Record<SceneStatus, { label: string; cls: string }> = {
  idle: { label: 'draft', cls: 'bg-[#f3f2f1] text-[#605e5c]' },
  queued: { label: 'queued', cls: 'bg-blue-100 text-blue-700' },
  running: { label: 'generating…', cls: 'bg-amber-100 text-amber-700' },
  done: { label: 'done', cls: 'bg-green-100 text-green-700' },
  error: { label: 'error', cls: 'bg-red-100 text-red-700' },
}

const ASSET_DOT: Record<AssetStatus, string> = {
  idle: 'bg-[#c8c6c4]',
  queued: 'bg-blue-400',
  running: 'bg-amber-400 animate-pulse',
  done: 'bg-green-500',
  error: 'bg-red-500',
  skipped: 'bg-[#e1dfdd]',
}

function SceneNodeComponent({ id, data, selected }: NodeProps<SceneNodeType>) {
  const generateScene = useStoryboardStore((s) => s.generateScene)
  const generateSceneImage = useStoryboardStore((s) => s.generateSceneImage)
  const generateSceneVideo = useStoryboardStore((s) => s.generateSceneVideo)
  const generateSceneAudio = useStoryboardStore((s) => s.generateSceneAudio)
  const uploadSceneImage = useStoryboardStore((s) => s.uploadSceneImage)
  const selectNode = useStoryboardStore((s) => s.selectNode)
  const fileRef = useRef<HTMLInputElement>(null)

  const running = data.status === 'running'
  const hasImage = data.imageStatus === 'done' && !!data.imageUrl
  const isError = data.status === 'error'
  const status = SCENE_STATUS_META[data.status]

  const onPickFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) void uploadSceneImage(id, file)
    e.target.value = ''
  }

  return (
    <div
      className={cn(
        'w-[300px] rounded-xl border bg-white shadow-sm transition-shadow',
        selected ? 'border-[#0078d4] shadow-md' : 'border-[#e1dfdd]',
      )}
    >
      <Handle type="target" position={Position.Left} className="!h-3 !w-3 !border-2 !border-white !bg-[#605e5c]" />
      <Handle type="source" position={Position.Right} className="!h-3 !w-3 !border-2 !border-white !bg-[#605e5c]" />

      {/* Header: order · title · media_mode · status */}
      <header className="flex items-center gap-2 border-b border-[#eee] px-3 py-2">
        <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-[#0078d4] text-[12px] font-bold text-white">
          {data.order}
        </span>
        <span className="flex-1 truncate text-[13px] font-semibold text-[#201f1e]">{data.title}</span>
        <span className="text-[13px]" title={data.mediaMode === 'video' ? 'Video clip' : 'Static image'}>
          {data.mediaMode === 'video' ? '🎥' : '🖼'}
        </span>
        <span className={cn('rounded px-1.5 py-0.5 text-[10px] font-medium', status.cls)}>{status.label}</span>
      </header>

      {/* Preview: image/clip + duration badge */}
      <div className="px-3 pt-3">
        <div className="relative aspect-video w-full overflow-hidden rounded-md bg-[#f3f2f1]">
          {data.imageUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={data.imageUrl} alt={data.title} className="h-full w-full object-cover" />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-[12px] text-[#a19f9d]">
              {running ? 'Generating…' : 'No image yet'}
            </div>
          )}
          {data.imageSource === 'manual' && hasImage && (
            <span className="absolute left-1.5 top-1.5 rounded bg-black/60 px-1.5 py-0.5 text-[10px] font-medium text-white">
              uploaded
            </span>
          )}
          {data.videoStatus === 'done' && (
            <span className="absolute bottom-1.5 left-1.5 flex items-center gap-1 rounded bg-black/60 px-1.5 py-0.5 text-[10px] font-medium text-white">
              <svg className="h-2.5 w-2.5" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z" /></svg>
              clip
            </span>
          )}
          <span className="absolute bottom-1.5 right-1.5 rounded bg-black/60 px-1.5 py-0.5 text-[10px] font-medium text-white">
            {data.durationSec}s
          </span>
        </div>
      </div>

      {/* Meta: prompt (2 lines) + dialogue (2 lines) */}
      <p className="line-clamp-2 px-3 pt-2 text-[12px] leading-snug text-[#605e5c]">
        {data.prompt || <span className="italic text-[#a19f9d]">No prompt — open the inspector to describe this scene.</span>}
      </p>
      {data.dialogue && (
        <p className="line-clamp-2 px-3 pt-1 text-[11.5px] italic leading-snug text-[#8a8886]">
          “{data.dialogue}”
        </p>
      )}

      {/* Asset status dots */}
      <div className="flex items-center gap-3 px-3 pb-2 pt-2 text-[10.5px] text-[#605e5c]">
        <span className="flex items-center gap-1"><i className={cn('h-2 w-2 rounded-full', ASSET_DOT[data.imageStatus])} /> image</span>
        <span className="flex items-center gap-1"><i className={cn('h-2 w-2 rounded-full', ASSET_DOT[data.videoStatus])} /> video</span>
        <span className="flex items-center gap-1"><i className={cn('h-2 w-2 rounded-full', ASSET_DOT[data.audioStatus])} /> audio</span>
      </div>

      {/* Progress bar while running */}
      {running && (
        <div className="mx-3 mb-2 h-1 overflow-hidden rounded-full bg-[#edebe9]">
          <div className="h-full bg-[#0078d4] transition-all" style={{ width: `${Math.round(data.progress * 100)}%` }} />
        </div>
      )}

      {data.error && <p className="mx-3 mb-2 rounded bg-red-50 px-2 py-1 text-[11px] text-red-600">{data.error}</p>}

      {/* Actions by status (SRD §2.3) */}
      <div className="flex flex-wrap gap-1.5 border-t border-[#eee] px-3 py-2">
        <input ref={fileRef} type="file" accept={UPLOAD_ACCEPT} onChange={onPickFile} className="hidden" />
        {isError ? (
          <ActionBtn primary onClick={() => generateScene(id)} disabled={running || !data.prompt}>🔁 Retry</ActionBtn>
        ) : !hasImage ? (
          <>
            <ActionBtn primary onClick={() => generateSceneImage(id)} disabled={running || !data.prompt}>⚡ Image</ActionBtn>
            <ActionBtn onClick={() => fileRef.current?.click()}>📁 Upload</ActionBtn>
          </>
        ) : (
          <>
            {data.mediaMode === 'video' && (
              <ActionBtn primary onClick={() => generateSceneVideo(id)} disabled={running}>
                {data.videoStatus === 'done' ? '🔁 Video' : '🎥 Video'}
              </ActionBtn>
            )}
            {data.dialogue.trim() && (
              <ActionBtn onClick={() => generateSceneAudio(id)} disabled={running}>🔊 Voice</ActionBtn>
            )}
            <ActionBtn onClick={() => generateSceneImage(id)} disabled={running} title="Regenerate image">🔁 Image</ActionBtn>
            <ActionBtn onClick={() => selectNode(id)}>✏️ Edit</ActionBtn>
          </>
        )}
      </div>
    </div>
  )
}

interface ActionBtnProps {
  children: React.ReactNode
  onClick: () => void
  disabled?: boolean
  primary?: boolean
  title?: string
}
function ActionBtn({ children, onClick, disabled, primary, title }: ActionBtnProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      title={title}
      className={cn(
        'rounded px-2 py-1.5 text-[12px] font-medium transition-colors disabled:opacity-50',
        primary
          ? 'bg-[#0078d4] text-white hover:bg-[#106ebe]'
          : 'border border-[#c8c6c4] text-[#323130] hover:bg-[#f3f2f1]',
      )}
    >
      {children}
    </button>
  )
}

export const SceneNode = memo(SceneNodeComponent)
