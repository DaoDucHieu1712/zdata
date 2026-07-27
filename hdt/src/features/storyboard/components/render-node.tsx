'use client'

import { memo } from 'react'
import { Handle, Position, type NodeProps } from '@xyflow/react'
import { cn } from '@/lib/utils/cn'
import { useStoryboardStore } from '../store'
import type { RenderNode as RenderNodeType } from '../types/storyboard.types'

function RenderNodeComponent({ data, selected }: NodeProps<RenderNodeType>) {
  const renderFinal = useStoryboardStore((s) => s.renderFinal)
  const busy = data.status === 'running'

  return (
    <div
      className={cn(
        'w-[260px] rounded-xl border-2 bg-white shadow-sm transition-shadow',
        selected ? 'border-[#e11d48]' : 'border-[#f5b3c4]',
      )}
    >
      <Handle type="target" position={Position.Left} className="!h-3 !w-3 !border-2 !border-white !bg-[#e11d48]" />

      <header className="flex items-center gap-2 rounded-t-[10px] bg-[#e11d48]/10 px-3 py-2">
        <svg className="h-4 w-4 text-[#e11d48]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8}>
          <rect x="3" y="5" width="18" height="14" rx="2" />
          <path d="M3 9h18M8 5v14" strokeLinecap="round" />
        </svg>
        <span className="text-[13px] font-semibold text-[#201f1e]">Render Video</span>
      </header>

      <div className="p-3">
        <div className="relative aspect-video w-full overflow-hidden rounded-md bg-black">
          {data.videoUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={data.videoUrl} alt="Final render" className="h-full w-full object-cover opacity-90" />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-[12px] text-white/60">
              {busy ? 'Rendering…' : 'Final video preview'}
            </div>
          )}
          {data.videoUrl && (
            <span className="absolute inset-0 flex items-center justify-center">
              <span className="flex h-9 w-9 items-center justify-center rounded-full bg-white/85">
                <svg className="h-4 w-4 text-black" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z" /></svg>
              </span>
            </span>
          )}
        </div>

        {data.error && <p className="mt-2 text-[11.5px] text-red-600">{data.error}</p>}

        <button
          type="button"
          onClick={renderFinal}
          disabled={busy}
          className="mt-3 w-full rounded bg-[#e11d48] px-2 py-1.5 text-[12.5px] font-medium text-white transition-colors hover:bg-[#be123c] disabled:opacity-50"
        >
          {busy ? 'Rendering…' : 'Render final video'}
        </button>
      </div>
    </div>
  )
}

export const RenderNode = memo(RenderNodeComponent)
