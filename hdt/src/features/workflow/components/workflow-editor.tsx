'use client'

import { ReactFlowProvider } from '@xyflow/react'
import { NodePalette } from './node-palette'
import { NodeInspector } from './node-inspector'
import { WorkflowToolbar } from './workflow-toolbar'
import { WorkflowCanvas } from './workflow-canvas'

/**
 * Full n8n-style workflow editor: palette (left) · canvas (centre) · inspector (right),
 * with a run/export toolbar on top. This is the feature's main entry component.
 */
export function WorkflowEditor() {
  return (
    <ReactFlowProvider>
      <div className="flex h-full flex-col overflow-hidden">
        <WorkflowToolbar />
        <div className="flex flex-1 overflow-hidden">
          <NodePalette />
          <div className="relative flex-1 overflow-hidden">
            <WorkflowCanvas />
          </div>
          <NodeInspector />
        </div>
      </div>
    </ReactFlowProvider>
  )
}
