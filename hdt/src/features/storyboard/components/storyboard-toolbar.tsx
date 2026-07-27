'use client'

import { useState } from 'react'
import { useStoryboardStore } from '../store'
import type { SceneNode } from '../types/storyboard.types'

type ProjectType = 'film' | 'vlog' | 'video'

/** Top toolbar: script breakdown, add scenes, generate all, and render. */
export function StoryboardToolbar() {
  const isBusy = useStoryboardStore((s) => s.isBusy)
  const sceneCount = useStoryboardStore((s) => s.nodes.filter((n) => n.data.kind === 'scene').length)
  const readyClips = useStoryboardStore(
    (s) => s.nodes.filter((n): n is SceneNode => n.data.kind === 'scene' && n.data.status === 'done').length,
  )
  const addScene = useStoryboardStore((s) => s.addScene)
  const generateAll = useStoryboardStore((s) => s.generateAll)
  const renderFinal = useStoryboardStore((s) => s.renderFinal)
  const breakdownFromScript = useStoryboardStore((s) => s.breakdownFromScript)

  const [scriptOpen, setScriptOpen] = useState(false)

  return (
    <>
      <div className="flex h-12 shrink-0 items-center gap-2 border-b border-[#e1dfdd] bg-white px-4">
        <div>
          <h1 className="text-[14px] font-semibold leading-tight text-[#201f1e]">Storyboard → Video</h1>
          <p className="text-[11px] leading-tight text-[#a19f9d]">
            {sceneCount} scenes · {readyClips} done
          </p>
        </div>

        <div className="ml-auto flex items-center gap-2">
          <ToolbarBtn onClick={() => setScriptOpen(true)}>
            <svg className="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8}>
              <path d="M4 6h16M4 12h16M4 18h10" strokeLinecap="round" />
            </svg>
            Breakdown from script
          </ToolbarBtn>
          <ToolbarBtn onClick={addScene}>
            <svg className="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}>
              <path d="M12 5v14M5 12h14" strokeLinecap="round" />
            </svg>
            Add scene
          </ToolbarBtn>
          <ToolbarBtn primary onClick={generateAll} disabled={isBusy}>
            <svg className="h-3.5 w-3.5" viewBox="0 0 24 24" fill="currentColor"><path d="M9.5 3 6 7 2 8.5 5 12l-.5 4.5L8.5 15 12 17l1-4.5L17 11l-4-2.5z" opacity=".9" /></svg>
            {isBusy ? 'Generating…' : 'Generate all'}
          </ToolbarBtn>
          <ToolbarBtn danger onClick={renderFinal} disabled={isBusy}>
            <svg className="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8}>
              <rect x="3" y="5" width="18" height="14" rx="2" /><path d="M3 9h18M8 5v14" strokeLinecap="round" />
            </svg>
            Render
          </ToolbarBtn>
        </div>
      </div>

      {scriptOpen && (
        <ScriptBreakdownModal
          onClose={() => setScriptOpen(false)}
          onSubmit={async (text, type) => {
            await breakdownFromScript(text, type)
            setScriptOpen(false)
          }}
        />
      )}
    </>
  )
}

interface ToolbarBtnProps {
  children: React.ReactNode
  onClick: () => void
  disabled?: boolean
  primary?: boolean
  danger?: boolean
}
function ToolbarBtn({ children, onClick, disabled, primary, danger }: ToolbarBtnProps) {
  const base = 'flex items-center gap-1.5 rounded px-3 py-1.5 text-[13px] font-medium transition-colors disabled:opacity-60'
  const skin = primary
    ? 'bg-[#0078d4] text-white hover:bg-[#106ebe]'
    : danger
      ? 'bg-[#e11d48] text-white hover:bg-[#be123c]'
      : 'border border-[#c8c6c4] text-[#323130] hover:bg-[#f3f2f1]'
  return (
    <button type="button" onClick={onClick} disabled={disabled} className={`${base} ${skin}`}>
      {children}
    </button>
  )
}

interface ScriptModalProps {
  onClose: () => void
  onSubmit: (text: string, type: ProjectType) => Promise<void>
}
function ScriptBreakdownModal({ onClose, onSubmit }: ScriptModalProps) {
  const [text, setText] = useState('')
  const [type, setType] = useState<ProjectType>('video')
  const [busy, setBusy] = useState(false)

  const submit = async () => {
    if (!text.trim() || busy) return
    setBusy(true)
    try {
      await onSubmit(text, type)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div
        className="flex w-full max-w-lg flex-col gap-3 rounded-xl bg-white p-5 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 className="text-[15px] font-semibold text-[#201f1e]">Auto-breakdown from script</h2>
        <p className="text-[12px] text-[#605e5c]">
          Paste your script or idea. The Cloud LLM splits it into scenes with prompts and dialogue.
        </p>

        <div className="flex items-center gap-2">
          <label className="text-[12.5px] font-medium text-[#323130]">Project type</label>
          <select
            value={type}
            onChange={(e) => setType(e.target.value as ProjectType)}
            className="h-8 rounded-md border border-[#d9d9d9] px-2 text-[13px]"
          >
            <option value="video">Video</option>
            <option value="film">Film</option>
            <option value="vlog">Vlog</option>
          </select>
        </div>

        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          rows={8}
          placeholder="Once upon a time, a lone traveler arrived at a neon-lit city…"
          className="w-full resize-y rounded-md border border-[#d9d9d9] px-3 py-2 text-[13px] outline-none focus:border-[#1677ff]"
        />

        <div className="flex justify-end gap-2">
          <button
            type="button"
            onClick={onClose}
            className="rounded border border-[#c8c6c4] px-3 py-1.5 text-[13px] font-medium text-[#323130] hover:bg-[#f3f2f1]"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={submit}
            disabled={!text.trim() || busy}
            className="rounded bg-[#0078d4] px-4 py-1.5 text-[13px] font-medium text-white hover:bg-[#106ebe] disabled:opacity-60"
          >
            {busy ? 'Generating…' : 'Create scenes'}
          </button>
        </div>
      </div>
    </div>
  )
}
