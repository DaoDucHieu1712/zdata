import type { Node, Edge } from '@xyflow/react'

/** The kinds of nodes available in the workflow palette. */
export type WorkflowNodeKind =
  | 'trigger'
  | 'http'
  | 'code'
  | 'condition'
  | 'delay'
  | 'output'

/** Execution status of a single node during a (simulated) run. */
export type NodeRunStatus = 'idle' | 'running' | 'success' | 'error'

/** Data payload carried by every workflow node (React Flow `Node<T>` generic). */
export interface WorkflowNodeData extends Record<string, unknown> {
  kind: WorkflowNodeKind
  label: string
  /** Free-form config the node editor writes to (url, method, expression, ms, …). */
  config: Record<string, unknown>
  status: NodeRunStatus
}

/** A React Flow node specialised with our data payload. */
export type WorkflowNode = Node<WorkflowNodeData>

/** Edges carry no extra data for this demo. */
export type WorkflowEdge = Edge

/** Static descriptor used to render the palette and to spawn new nodes. */
export interface NodeDefinition {
  kind: WorkflowNodeKind
  label: string
  description: string
  /** Tailwind accent colour token, e.g. `#0078d4`. */
  accent: string
  /** Whether the node accepts an incoming connection. */
  hasTarget: boolean
  /** Whether the node emits an outgoing connection. */
  hasSource: boolean
  /** Default config seeded onto a freshly-dropped node. */
  defaultConfig: Record<string, unknown>
}

/** Shape persisted / exported as JSON. */
export interface WorkflowGraph {
  nodes: WorkflowNode[]
  edges: WorkflowEdge[]
}
