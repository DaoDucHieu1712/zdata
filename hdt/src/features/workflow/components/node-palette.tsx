'use client'

import type { DragEvent } from 'react'
import { NODE_PALETTE } from '../config/node-definitions'
import type { WorkflowNodeKind } from '../types/workflow.types'

/** MIME type used to carry the node kind through the HTML5 drag payload. */
export const DND_MIME = 'application/reactflow'

/**
 * Left rail listing every available node. Nodes are dragged from here onto the
 * canvas; {@link WorkflowCanvas} reads {@link DND_MIME} on drop.
 */
export function NodePalette() {
  const onDragStart = (event: DragEvent<HTMLDivElement>, kind: WorkflowNodeKind) => {
    event.dataTransfer.setData(DND_MIME, kind)
    event.dataTransfer.effectAllowed = 'move'
  }

  return (
    <aside className="flex w-56 shrink-0 flex-col gap-2 overflow-y-auto border-r border-[#e1dfdd] bg-[#faf9f8] p-3">
      <h2 className="px-1 text-[11px] font-semibold uppercase tracking-wide text-[#a19f9d]">Nodes</h2>
      {NODE_PALETTE.map((def) => (
        <div
          key={def.kind}
          draggable
          onDragStart={(e) => onDragStart(e, def.kind)}
          className="cursor-grab rounded-md border border-[#e1dfdd] bg-white p-2.5 shadow-sm transition-colors hover:border-[#0078d4] active:cursor-grabbing"
        >
          <div className="flex items-center gap-2">
            <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ backgroundColor: def.accent }} />
            <span className="text-[13px] font-semibold text-[#201f1e]">{def.label}</span>
          </div>
          <p className="mt-1 text-[11.5px] leading-snug text-[#605e5c]">{def.description}</p>
        </div>
      ))}
      <p className="mt-auto px-1 pt-2 text-[11px] leading-snug text-[#a19f9d]">
        Drag a node onto the canvas, then connect the handles to build a flow.
      </p>
    </aside>
  )
}
