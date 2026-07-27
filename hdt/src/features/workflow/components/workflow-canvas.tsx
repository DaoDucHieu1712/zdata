'use client'

import { useCallback, useMemo, useRef, type DragEvent } from 'react'
import {
  Background,
  BackgroundVariant,
  Controls,
  MiniMap,
  ReactFlow,
  useReactFlow,
  type NodeTypes,
  type NodeMouseHandler,
} from '@xyflow/react'
import '@xyflow/react/dist/style.css'
import { useWorkflowStore } from '../store'
import { NODE_DEFINITIONS } from '../config/node-definitions'
import { WorkflowNode } from './workflow-node'
import { DND_MIME } from './node-palette'
import type { WorkflowNode as WorkflowNodeType, WorkflowNodeKind } from '../types/workflow.types'

/**
 * The React Flow canvas, bound to {@link useWorkflowStore}. Handles drag-and-drop
 * creation from the palette, connection creation, and node selection.
 * Must be rendered inside a {@link ReactFlowProvider} (see {@link WorkflowEditor}).
 */
export function WorkflowCanvas() {
  const wrapperRef = useRef<HTMLDivElement>(null)
  const { screenToFlowPosition } = useReactFlow()

  const nodes = useWorkflowStore((s) => s.nodes)
  const edges = useWorkflowStore((s) => s.edges)
  const onNodesChange = useWorkflowStore((s) => s.onNodesChange)
  const onEdgesChange = useWorkflowStore((s) => s.onEdgesChange)
  const onConnect = useWorkflowStore((s) => s.onConnect)
  const addNode = useWorkflowStore((s) => s.addNode)
  const selectNode = useWorkflowStore((s) => s.selectNode)

  const nodeTypes = useMemo<NodeTypes>(() => ({ workflow: WorkflowNode }), [])

  const onDragOver = useCallback((event: DragEvent) => {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }, [])

  const onDrop = useCallback(
    (event: DragEvent) => {
      event.preventDefault()
      const kind = event.dataTransfer.getData(DND_MIME) as WorkflowNodeKind
      if (!kind || !NODE_DEFINITIONS[kind]) return
      const position = screenToFlowPosition({ x: event.clientX, y: event.clientY })
      addNode(kind, position)
    },
    [screenToFlowPosition, addNode],
  )

  const onNodeClick = useCallback<NodeMouseHandler<WorkflowNodeType>>(
    (_, node) => selectNode(node.id),
    [selectNode],
  )

  return (
    <div ref={wrapperRef} className="h-full w-full" onDragOver={onDragOver} onDrop={onDrop}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        nodeTypes={nodeTypes}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        onNodeClick={onNodeClick}
        onPaneClick={() => selectNode(null)}
        fitView
        proOptions={{ hideAttribution: true }}
        defaultEdgeOptions={{ animated: true }}
      >
        <Background variant={BackgroundVariant.Dots} gap={18} size={1.5} color="#d0cfce" />
        <Controls showInteractive={false} />
        <MiniMap
          pannable
          zoomable
          nodeColor={(n) => NODE_DEFINITIONS[(n.data as WorkflowNodeType['data']).kind]?.accent ?? '#605e5c'}
        />
      </ReactFlow>
    </div>
  )
}
