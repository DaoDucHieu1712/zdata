import type { NodeDefinition, WorkflowNodeKind } from '../types/workflow.types'

/**
 * Static catalogue of every node type the editor can create.
 * Keyed lookups use {@link NODE_DEFINITIONS}; ordered rendering uses {@link NODE_PALETTE}.
 */
export const NODE_PALETTE: NodeDefinition[] = [
  {
    kind: 'trigger',
    label: 'Trigger',
    description: 'Starts the workflow (manual / webhook).',
    accent: '#16a34a',
    hasTarget: false,
    hasSource: true,
    defaultConfig: { event: 'manual' },
  },
  {
    kind: 'http',
    label: 'HTTP Request',
    description: 'Call an external API endpoint.',
    accent: '#0078d4',
    hasTarget: true,
    hasSource: true,
    defaultConfig: { method: 'GET', url: 'https://api.example.com' },
  },
  {
    kind: 'code',
    label: 'Code',
    description: 'Run a JavaScript expression on the payload.',
    accent: '#9333ea',
    hasTarget: true,
    hasSource: true,
    defaultConfig: { expression: 'return input' },
  },
  {
    kind: 'condition',
    label: 'Condition',
    description: 'Branch the flow on a boolean expression.',
    accent: '#d97706',
    hasTarget: true,
    hasSource: true,
    defaultConfig: { expression: 'input.value > 0' },
  },
  {
    kind: 'delay',
    label: 'Delay',
    description: 'Wait a fixed amount of time.',
    accent: '#0891b2',
    hasTarget: true,
    hasSource: true,
    defaultConfig: { ms: 1000 },
  },
  {
    kind: 'output',
    label: 'Output',
    description: 'Terminal node — collects the result.',
    accent: '#e11d48',
    hasTarget: true,
    hasSource: false,
    defaultConfig: {},
  },
]

export const NODE_DEFINITIONS: Record<WorkflowNodeKind, NodeDefinition> =
  NODE_PALETTE.reduce(
    (acc, def) => {
      acc[def.kind] = def
      return acc
    },
    {} as Record<WorkflowNodeKind, NodeDefinition>,
  )
