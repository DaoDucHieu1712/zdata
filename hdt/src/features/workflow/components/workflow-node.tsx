'use client'

import { memo } from 'react'
import { Handle, Position, type NodeProps } from '@xyflow/react'
import { cn } from '@/lib/utils/cn'
import { NODE_DEFINITIONS } from '../config/node-definitions'
import type { WorkflowNode as WorkflowNodeType, NodeRunStatus } from '../types/workflow.types'

const STATUS_RING: Record<NodeRunStatus, string> = {
  idle: 'ring-transparent',
  running: 'ring-amber-400 animate-pulse',
  success: 'ring-green-500',
  error: 'ring-red-500',
}

const STATUS_DOT: Record<NodeRunStatus, string> = {
  idle: 'bg-[#c8c6c4]',
  running: 'bg-amber-400',
  success: 'bg-green-500',
  error: 'bg-red-500',
}

/** Renders a single workflow node on the canvas. Registered as node type `workflow`. */
function WorkflowNodeComponent({ data, selected }: NodeProps<WorkflowNodeType>) {
  const def = NODE_DEFINITIONS[data.kind]
  const configPreview = summariseConfig(data.config)

  return (
    <div
      className={cn(
        'w-56 rounded-lg border bg-white shadow-sm ring-2 transition-shadow',
        selected ? 'border-[#0078d4] shadow-md' : 'border-[#e1dfdd]',
        STATUS_RING[data.status],
      )}
    >
      {def.hasTarget && (
        <Handle
          type="target"
          position={Position.Left}
          className="!h-3 !w-3 !border-2 !border-white !bg-[#605e5c]"
        />
      )}

      <header
        className="flex items-center gap-2 rounded-t-lg px-3 py-2"
        style={{ backgroundColor: `${def.accent}14`, borderBottom: `2px solid ${def.accent}` }}
      >
        <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ backgroundColor: def.accent }} />
        <span className="flex-1 truncate text-[13px] font-semibold text-[#201f1e]">{data.label}</span>
        <span className={cn('h-2 w-2 shrink-0 rounded-full', STATUS_DOT[data.status])} title={data.status} />
      </header>

      <div className="px-3 py-2">
        <p className="text-[11px] uppercase tracking-wide text-[#a19f9d]">{def.kind}</p>
        {configPreview && (
          <p className="mt-0.5 truncate font-mono text-[11.5px] text-[#605e5c]">{configPreview}</p>
        )}
      </div>

      {def.hasSource && (
        <Handle
          type="source"
          position={Position.Right}
          className="!h-3 !w-3 !border-2 !border-white !bg-[#605e5c]"
        />
      )}
    </div>
  )
}

function summariseConfig(config: Record<string, unknown>): string {
  const entries = Object.entries(config)
  if (entries.length === 0) return ''
  const [key, value] = entries[0]
  return `${key}: ${String(value)}`
}

export const WorkflowNode = memo(WorkflowNodeComponent)
