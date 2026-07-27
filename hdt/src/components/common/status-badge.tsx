import { cn } from '@/lib/utils/cn'

const DEFAULT_COLORS: Record<string, string> = {
  // green — completed / active
  published:  'bg-green-100 text-green-700',
  active:     'bg-green-100 text-green-700',
  confirmed:  'bg-green-100 text-green-700',
  delivered:  'bg-green-100 text-green-700',
  success:    'bg-green-100 text-green-700',
  // yellow — in-progress / waiting
  draft:      'bg-yellow-100 text-yellow-700',
  pending:    'bg-yellow-100 text-yellow-700',
  processing: 'bg-yellow-100 text-yellow-700',
  // blue — en-route / info
  shipped:    'bg-blue-100 text-blue-700',
  in_progress: 'bg-blue-100 text-blue-700',
  // gray — inactive / terminal
  archived:   'bg-gray-100 text-gray-500',
  inactive:   'bg-gray-100 text-gray-500',
  closed:     'bg-gray-100 text-gray-500',
  // red — failure / cancelled
  cancelled:  'bg-red-100 text-red-600',
  rejected:   'bg-red-100 text-red-600',
  failed:     'bg-red-100 text-red-600',
}

export interface StatusBadgeProps {
  status: string
  /** Override or extend the default color map */
  colorMap?: Record<string, string>
  className?: string
}

export function StatusBadge({ status, colorMap, className }: StatusBadgeProps) {
  const resolved = colorMap ? { ...DEFAULT_COLORS, ...colorMap } : DEFAULT_COLORS
  const style = resolved[status] ?? 'bg-gray-100 text-gray-500'
  return (
    <span
      className={cn(
        'inline-flex rounded-full px-2 py-0.5 text-xs font-medium capitalize',
        style,
        className,
      )}
    >
      {status}
    </span>
  )
}
