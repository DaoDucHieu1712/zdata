import { cn } from '@/lib/utils/cn'

export interface BulkAction {
  label: string
  onClick: () => void
  variant?: 'danger' | 'primary'
}

export interface BulkActionBarProps {
  count: number
  entityLabel?: string
  actions: BulkAction[]
  onClear: () => void
  className?: string
}

export function BulkActionBar({
  count,
  entityLabel = 'item',
  actions,
  onClear,
  className,
}: BulkActionBarProps) {
  if (count === 0) return null
  return (
    <div
      className={cn(
        'flex items-center gap-3 rounded-md border border-blue-200 bg-blue-50 px-4 py-2',
        className,
      )}
    >
      <span className="text-sm font-medium text-blue-700">
        {count} {entityLabel}{count > 1 ? 's' : ''} selected
      </span>
      <div className="ml-auto flex items-center gap-2">
        {actions.map((action) => (
          <button
            key={action.label}
            type="button"
            onClick={action.onClick}
            className={cn(
              'rounded px-3 py-1 text-xs font-medium transition',
              action.variant === 'danger'
                ? 'bg-red-600 text-white hover:bg-red-700'
                : 'bg-blue-600 text-white hover:bg-blue-700',
            )}
          >
            {action.label}
          </button>
        ))}
        <button
          type="button"
          onClick={onClear}
          className="text-xs text-gray-500 hover:text-gray-700"
        >
          Cancel
        </button>
      </div>
    </div>
  )
}
