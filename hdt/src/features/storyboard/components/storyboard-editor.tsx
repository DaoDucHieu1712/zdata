'use client'

import { useEffect } from 'react'
import { ReactFlowProvider } from '@xyflow/react'
import { useStoryboardStore } from '../store'
import { StoryboardToolbar } from './storyboard-toolbar'
import { StoryboardCanvas } from './storyboard-canvas'
import { SceneInspector } from './scene-inspector'

/**
 * Storyboard-to-video editor (SRS §3.3): each scene node is described, then
 * generates an image (text→image), a clip (image→video) and voiceover (TTS),
 * and a terminal Render node stitches the results. Transition edges determine
 * export order (FR-SB-02b) and node/viewport layout auto-saves (FR-SB-02).
 */
export function StoryboardEditor() {
  const hydrate = useStoryboardStore((s) => s.hydrate)

  // Load any saved layout on the client only, to avoid SSR hydration mismatch.
  useEffect(() => hydrate(), [hydrate])

  return (
    <ReactFlowProvider>
      <div className="flex h-full flex-col overflow-hidden">
        <StoryboardToolbar />
        <div className="flex flex-1 overflow-hidden">
          <div className="relative flex-1 overflow-hidden">
            <StoryboardCanvas />
          </div>
          <SceneInspector />
        </div>
      </div>
    </ReactFlowProvider>
  )
}
