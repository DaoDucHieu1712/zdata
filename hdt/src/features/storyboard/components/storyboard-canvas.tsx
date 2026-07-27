'use client'

import { useCallback, useMemo } from 'react'
import {
  Background,
  BackgroundVariant,
  Controls,
  MiniMap,
  ReactFlow,
  type NodeMouseHandler,
  type NodeTypes,
  type Viewport,
} from '@xyflow/react'
import '@xyflow/react/dist/style.css'
import { useStoryboardStore } from '../store'
import { SceneNode } from './scene-node'
import { RenderNode } from './render-node'
import type { StoryboardNode } from '../types/storyboard.types'

/** React Flow canvas bound to {@link useStoryboardStore}. Renders inside a ReactFlowProvider. */
export function StoryboardCanvas() {
  const nodes = useStoryboardStore((s) => s.nodes)
  const edges = useStoryboardStore((s) => s.edges)
  const viewport = useStoryboardStore((s) => s.viewport)
  const onNodesChange = useStoryboardStore((s) => s.onNodesChange)
  const onEdgesChange = useStoryboardStore((s) => s.onEdgesChange)
  const onConnect = useStoryboardStore((s) => s.onConnect)
  const selectNode = useStoryboardStore((s) => s.selectNode)
  const saveLayout = useStoryboardStore((s) => s.saveLayout)
  const setViewport = useStoryboardStore((s) => s.setViewport)

  const nodeTypes = useMemo<NodeTypes>(() => ({ scene: SceneNode, render: RenderNode }), [])

  const onNodeClick = useCallback<NodeMouseHandler<StoryboardNode>>(
    (_, node) => selectNode(node.id),
    [selectNode],
  )
  const onMoveEnd = useCallback((_: unknown, vp: Viewport) => setViewport(vp), [setViewport])

  // Restore saved viewport when present; otherwise fit the initial layout.
  const isDefaultViewport = viewport.x === 0 && viewport.y === 0 && viewport.zoom === 1

  return (
    <ReactFlow
      nodes={nodes}
      edges={edges}
      nodeTypes={nodeTypes}
      onNodesChange={onNodesChange}
      onEdgesChange={onEdgesChange}
      onConnect={onConnect}
      onNodeClick={onNodeClick}
      onNodeDragStop={saveLayout}
      onMoveEnd={onMoveEnd}
      onPaneClick={() => selectNode(null)}
      defaultViewport={viewport}
      fitView={isDefaultViewport}
      minZoom={0.3}
      proOptions={{ hideAttribution: true }}
      defaultEdgeOptions={{ animated: true }}
    >
      <Background variant={BackgroundVariant.Dots} gap={18} size={1.5} color="#d0cfce" />
      <Controls showInteractive={false} />
      <MiniMap pannable zoomable nodeColor={(n) => (n.type === 'render' ? '#e11d48' : '#0078d4')} />
    </ReactFlow>
  )
}
