'use client'

import { useWorkflowStore } from '../store'
import type { WorkflowGraph } from '../types/workflow.types'

/** Top toolbar: run / reset the simulation and export / import the graph as JSON. */
export function WorkflowToolbar() {
  const isRunning = useWorkflowStore((s) => s.isRunning)
  const nodeCount = useWorkflowStore((s) => s.nodes.length)
  const edgeCount = useWorkflowStore((s) => s.edges.length)
  const runWorkflow = useWorkflowStore((s) => s.runWorkflow)
  const resetStatuses = useWorkflowStore((s) => s.resetStatuses)
  const clear = useWorkflowStore((s) => s.clear)

  const onExport = () => {
    const { nodes, edges } = useWorkflowStore.getState()
    const graph: WorkflowGraph = { nodes, edges }
    const blob = new Blob([JSON.stringify(graph, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'workflow.json'
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="flex h-12 shrink-0 items-center gap-2 border-b border-[#e1dfdd] bg-white px-4">
      <h1 className="text-[14px] font-semibold text-[#201f1e]">Workflow</h1>
      <span className="text-[12px] text-[#a19f9d]">
        {nodeCount} nodes · {edgeCount} connections
      </span>

      <div className="ml-auto flex items-center gap-2">
        <button
          type="button"
          onClick={runWorkflow}
          disabled={isRunning}
          className="flex items-center gap-1.5 rounded bg-[#16a34a] px-3 py-1.5 text-[13px] font-medium text-white transition-colors hover:bg-[#15803d] disabled:opacity-60"
        >
          <svg className="h-3.5 w-3.5" viewBox="0 0 24 24" fill="currentColor">
            <path d="M8 5v14l11-7z" />
          </svg>
          {isRunning ? 'Running…' : 'Run'}
        </button>
        <button
          type="button"
          onClick={resetStatuses}
          className="rounded border border-[#c8c6c4] px-3 py-1.5 text-[13px] font-medium text-[#323130] transition-colors hover:bg-[#f3f2f1]"
        >
          Reset
        </button>
        <button
          type="button"
          onClick={onExport}
          className="rounded border border-[#c8c6c4] px-3 py-1.5 text-[13px] font-medium text-[#323130] transition-colors hover:bg-[#f3f2f1]"
        >
          Export
        </button>
        <button
          type="button"
          onClick={clear}
          className="rounded border border-[#c8c6c4] px-3 py-1.5 text-[13px] font-medium text-[#323130] transition-colors hover:bg-[#f3f2f1]"
        >
          Clear
        </button>
      </div>
    </div>
  )
}
