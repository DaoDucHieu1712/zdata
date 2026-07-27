'use client'

import { useWorkflowStore } from '../store'
import { NODE_DEFINITIONS } from '../config/node-definitions'

/**
 * Right rail that edits the currently-selected node's label and config.
 * Renders a generic key/value editor driven by whatever keys the node's
 * config object holds, so it works for every node kind without special-casing.
 */
export function NodeInspector() {
  const selectedId = useWorkflowStore((s) => s.selectedNodeId)
  const node = useWorkflowStore((s) => s.nodes.find((n) => n.id === s.selectedNodeId))
  const updateNodeConfig = useWorkflowStore((s) => s.updateNodeConfig)
  const updateNodeLabel = useWorkflowStore((s) => s.updateNodeLabel)
  const removeNode = useWorkflowStore((s) => s.removeNode)

  if (!selectedId || !node) {
    return (
      <aside className="flex w-72 shrink-0 items-center justify-center border-l border-[#e1dfdd] bg-[#faf9f8] p-4">
        <p className="text-center text-[12.5px] text-[#a19f9d]">
          Select a node to edit its settings.
        </p>
      </aside>
    )
  }

  const def = NODE_DEFINITIONS[node.data.kind]

  return (
    <aside className="flex w-72 shrink-0 flex-col overflow-y-auto border-l border-[#e1dfdd] bg-[#faf9f8]">
      <header className="flex items-center gap-2 border-b border-[#e1dfdd] px-4 py-3">
        <span className="h-3 w-3 rounded-full" style={{ backgroundColor: def.accent }} />
        <span className="text-[13px] font-semibold text-[#201f1e]">{def.label}</span>
        <span className="ml-auto text-[11px] uppercase tracking-wide text-[#a19f9d]">{node.data.kind}</span>
      </header>

      <div className="flex flex-col gap-4 p-4">
        <Field label="Label">
          <input
            value={node.data.label}
            onChange={(e) => updateNodeLabel(node.id, e.target.value)}
            className="w-full rounded border border-[#c8c6c4] px-2.5 py-1.5 text-[13px] outline-none focus:border-[#0078d4]"
          />
        </Field>

        {Object.entries(node.data.config).map(([key, value]) => (
          <Field key={key} label={key}>
            <input
              value={String(value)}
              onChange={(e) => updateNodeConfig(node.id, { [key]: coerce(value, e.target.value) })}
              className="w-full rounded border border-[#c8c6c4] px-2.5 py-1.5 font-mono text-[12.5px] outline-none focus:border-[#0078d4]"
            />
          </Field>
        ))}

        {Object.keys(node.data.config).length === 0 && (
          <p className="text-[12px] text-[#a19f9d]">This node has no configurable fields.</p>
        )}

        <button
          type="button"
          onClick={() => removeNode(node.id)}
          className="mt-2 rounded border border-red-200 px-3 py-1.5 text-[12.5px] font-medium text-red-600 transition-colors hover:bg-red-50"
        >
          Delete node
        </button>
      </div>
    </aside>
  )
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="flex flex-col gap-1">
      <span className="text-[11px] font-medium uppercase tracking-wide text-[#605e5c]">{label}</span>
      {children}
    </label>
  )
}

/** Preserve the original config value's primitive type when writing edits back. */
function coerce(previous: unknown, next: string): unknown {
  if (typeof previous === 'number') {
    const n = Number(next)
    return Number.isNaN(n) ? previous : n
  }
  if (typeof previous === 'boolean') return next === 'true'
  return next
}
