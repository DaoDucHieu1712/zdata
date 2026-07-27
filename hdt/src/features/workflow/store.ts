import { create } from 'zustand'
import {
  addEdge,
  applyEdgeChanges,
  applyNodeChanges,
  type Connection,
  type EdgeChange,
  type NodeChange,
  type XYPosition,
} from '@xyflow/react'
import { NODE_DEFINITIONS } from './config/node-definitions'
import type {
  WorkflowEdge,
  WorkflowGraph,
  WorkflowNode,
  WorkflowNodeData,
  WorkflowNodeKind,
} from './types/workflow.types'

let nodeSeq = 0
const nextId = (kind: WorkflowNodeKind) => `${kind}-${++nodeSeq}`

/** A small starter graph so the canvas isn't empty on first load. */
function seedGraph(): WorkflowGraph {
  const trigger: WorkflowNode = {
    id: nextId('trigger'),
    type: 'workflow',
    position: { x: 80, y: 160 },
    data: { kind: 'trigger', label: 'Trigger', config: { event: 'manual' }, status: 'idle' },
  }
  const http: WorkflowNode = {
    id: nextId('http'),
    type: 'workflow',
    position: { x: 360, y: 160 },
    data: {
      kind: 'http',
      label: 'HTTP Request',
      config: { method: 'GET', url: 'https://api.example.com' },
      status: 'idle',
    },
  }
  const output: WorkflowNode = {
    id: nextId('output'),
    type: 'workflow',
    position: { x: 640, y: 160 },
    data: { kind: 'output', label: 'Output', config: {}, status: 'idle' },
  }
  return {
    nodes: [trigger, http, output],
    edges: [
      { id: `${trigger.id}->${http.id}`, source: trigger.id, target: http.id },
      { id: `${http.id}->${output.id}`, source: http.id, target: output.id },
    ],
  }
}

interface WorkflowState {
  nodes: WorkflowNode[]
  edges: WorkflowEdge[]
  selectedNodeId: string | null
  isRunning: boolean

  // ── React Flow change handlers ───────────────────────────────
  onNodesChange: (changes: NodeChange<WorkflowNode>[]) => void
  onEdgesChange: (changes: EdgeChange<WorkflowEdge>[]) => void
  onConnect: (connection: Connection) => void

  // ── Editor actions ───────────────────────────────────────────
  addNode: (kind: WorkflowNodeKind, position: XYPosition) => void
  updateNodeConfig: (id: string, config: Record<string, unknown>) => void
  updateNodeLabel: (id: string, label: string) => void
  removeNode: (id: string) => void
  selectNode: (id: string | null) => void

  // ── Graph-level actions ──────────────────────────────────────
  runWorkflow: () => Promise<void>
  resetStatuses: () => void
  loadGraph: (graph: WorkflowGraph) => void
  clear: () => void
}

const initial = seedGraph()

export const useWorkflowStore = create<WorkflowState>((set, get) => ({
  nodes: initial.nodes,
  edges: initial.edges,
  selectedNodeId: null,
  isRunning: false,

  onNodesChange: (changes) =>
    set((s) => ({ nodes: applyNodeChanges(changes, s.nodes) })),

  onEdgesChange: (changes) =>
    set((s) => ({ edges: applyEdgeChanges(changes, s.edges) })),

  onConnect: (connection) =>
    set((s) => ({ edges: addEdge({ ...connection, animated: true }, s.edges) })),

  addNode: (kind, position) => {
    const def = NODE_DEFINITIONS[kind]
    const node: WorkflowNode = {
      id: nextId(kind),
      type: 'workflow',
      position,
      data: {
        kind,
        label: def.label,
        config: { ...def.defaultConfig },
        status: 'idle',
      },
    }
    set((s) => ({ nodes: [...s.nodes, node], selectedNodeId: node.id }))
  },

  updateNodeConfig: (id, config) =>
    set((s) => ({
      nodes: s.nodes.map((n) =>
        n.id === id ? { ...n, data: { ...n.data, config: { ...n.data.config, ...config } } } : n,
      ),
    })),

  updateNodeLabel: (id, label) =>
    set((s) => ({
      nodes: s.nodes.map((n) => (n.id === id ? { ...n, data: { ...n.data, label } } : n)),
    })),

  removeNode: (id) =>
    set((s) => ({
      nodes: s.nodes.filter((n) => n.id !== id),
      edges: s.edges.filter((e) => e.source !== id && e.target !== id),
      selectedNodeId: s.selectedNodeId === id ? null : s.selectedNodeId,
    })),

  selectNode: (selectedNodeId) => set({ selectedNodeId }),

  resetStatuses: () =>
    set((s) => ({
      nodes: s.nodes.map((n) => setStatus(n, 'idle')),
    })),

  /**
   * Simulated execution: walks the graph in topological order starting from
   * trigger nodes and flips each node's status idle → running → success.
   * A `code`/`condition` node whose expression contains `throw` fails the run.
   */
  runWorkflow: async () => {
    if (get().isRunning) return
    const order = topoOrder(get().nodes, get().edges)
    set({ isRunning: true })
    get().resetStatuses()

    for (const id of order) {
      set((s) => ({ nodes: s.nodes.map((n) => (n.id === id ? setStatus(n, 'running') : n)) }))
      await sleep(450)

      const node = get().nodes.find((n) => n.id === id)
      const expr = String(node?.data.config.expression ?? '')
      const failed = expr.includes('throw')
      set((s) => ({
        nodes: s.nodes.map((n) =>
          n.id === id ? setStatus(n, failed ? 'error' : 'success') : n,
        ),
      }))
      if (failed) break
    }
    set({ isRunning: false })
  },

  loadGraph: (graph) => set({ nodes: graph.nodes, edges: graph.edges, selectedNodeId: null }),

  clear: () => set({ nodes: [], edges: [], selectedNodeId: null }),
}))

// ── helpers ────────────────────────────────────────────────────

function setStatus(node: WorkflowNode, status: WorkflowNodeData['status']): WorkflowNode {
  return { ...node, data: { ...node.data, status } }
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms))

/** Kahn's algorithm; nodes with cycles/no incoming edge run first. */
function topoOrder(nodes: WorkflowNode[], edges: WorkflowEdge[]): string[] {
  const indegree = new Map<string, number>(nodes.map((n) => [n.id, 0]))
  const adj = new Map<string, string[]>(nodes.map((n) => [n.id, []]))
  for (const e of edges) {
    if (!indegree.has(e.source) || !indegree.has(e.target)) continue
    indegree.set(e.target, (indegree.get(e.target) ?? 0) + 1)
    adj.get(e.source)!.push(e.target)
  }
  const queue = nodes.filter((n) => (indegree.get(n.id) ?? 0) === 0).map((n) => n.id)
  const order: string[] = []
  while (queue.length) {
    const id = queue.shift()!
    order.push(id)
    for (const next of adj.get(id) ?? []) {
      indegree.set(next, (indegree.get(next) ?? 1) - 1)
      if (indegree.get(next) === 0) queue.push(next)
    }
  }
  // Append any nodes left out by cycles so they still get a status.
  for (const n of nodes) if (!order.includes(n.id)) order.push(n.id)
  return order
}
