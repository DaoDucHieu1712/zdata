import { cn } from '@/lib/utils/cn'

export interface TagListProps {
  tags: string[]
  className?: string
}

export function TagList({ tags, className }: TagListProps) {
  if (tags.length === 0) return <span className="text-xs text-gray-400">—</span>
  return (
    <div className={cn('flex flex-wrap gap-1', className)}>
      {tags.map((tag) => (
        <span key={tag} className="rounded bg-blue-50 px-1.5 py-0.5 text-xs text-blue-600">
          {tag}
        </span>
      ))}
    </div>
  )
}
