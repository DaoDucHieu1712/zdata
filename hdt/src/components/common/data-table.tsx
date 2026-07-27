'use client'

import { useCallback, useMemo, useState } from 'react'
import type { ReactNode } from 'react'
import { cn } from '@/lib/utils/cn'

export interface ColumnDef<T> {
  key: string
  header: string | ReactNode
  accessor?: keyof T | ((row: T) => ReactNode)
  render?: (row: T, index: number) => ReactNode
  width?: string
  sortable?: boolean
  align?: 'left' | 'center' | 'right'
}

export interface PaginationState {
  page: number
  pageSize: number
  total: number
}

export interface DataTableProps<T extends object> {
  columns: ColumnDef<T>[]
  data: T[]
  rowKey: keyof T | ((row: T) => string)
  loading?: boolean
  pagination?: PaginationState
  selectable?: boolean
  className?: string
  onRowClick?: (row: T, index: number) => void
  onSort?: (key: string, direction: 'asc' | 'desc') => void
  onPageChange?: (page: number, pageSize: number) => void
  onSelectionChange?: (rows: T[]) => void
}

type SortState = { key: string; direction: 'asc' | 'desc' } | null

const PAGE_SIZE_OPTIONS = [10, 20, 50, 100]
const SKELETON_WIDTHS = [55, 70, 45, 80, 60, 75, 50, 65, 40, 72]

function getKey<T extends object>(row: T, rowKey: DataTableProps<T>['rowKey']): string {
  if (typeof rowKey === 'function') return rowKey(row)
  return String(row[rowKey])
}

function getCellValue<T extends object>(row: T, col: ColumnDef<T>, index: number): ReactNode {
  if (col.render) return col.render(row, index)
  if (typeof col.accessor === 'function') return col.accessor(row)
  if (col.accessor !== undefined) return String(row[col.accessor] ?? '')
  return String((row as Record<string, unknown>)[col.key] ?? '')
}

// ── Sort icon ──────────────────────────────────────────────────────────────────

function SortIcon({ active, direction }: { active: boolean; direction: 'asc' | 'desc' | null }) {
  return (
    <span className="ml-1 inline-flex flex-col gap-[1px] shrink-0">
      <span
        className={cn(
          'block h-0 w-0 border-x-[3.5px] border-b-[4px] border-x-transparent transition-colors',
          active && direction === 'asc' ? 'border-b-[#0078d4]' : 'border-b-[#c8c6c4]',
        )}
      />
      <span
        className={cn(
          'block h-0 w-0 border-x-[3.5px] border-t-[4px] border-x-transparent transition-colors',
          active && direction === 'desc' ? 'border-t-[#0078d4]' : 'border-t-[#c8c6c4]',
        )}
      />
    </span>
  )
}

// ── Pagination ─────────────────────────────────────────────────────────────────

function getPageNumbers(current: number, total: number): (number | '...')[] {
  if (total <= 9) return Array.from({ length: total }, (_, i) => i + 1)

  const pages: (number | '...')[] = [1]
  const left  = Math.max(2, current - 2)
  const right = Math.min(total - 1, current + 2)

  if (left > 2) pages.push('...')
  for (let i = left; i <= right; i++) pages.push(i)
  if (right < total - 1) pages.push('...')

  pages.push(total)
  return pages
}

interface TablePaginationProps {
  pagination: PaginationState
  totalPages: number
  onPageChange?: (page: number, pageSize: number) => void
}

function TablePagination({ pagination, totalPages, onPageChange }: TablePaginationProps) {
  const { page, pageSize, total } = pagination
  const from = total === 0 ? 0 : (page - 1) * pageSize + 1
  const to   = Math.min(page * pageSize, total)
  const pages = getPageNumbers(page, totalPages)

  const atFirst = page <= 1
  const atLast  = page >= totalPages

  const navBtn = (disabled: boolean) =>
    cn(
      'flex h-7 w-7 items-center justify-center rounded text-[12px] transition-colors select-none',
      disabled
        ? 'text-[#c8c6c4] cursor-not-allowed'
        : 'text-[#605e5c] hover:bg-[#edebe9] cursor-pointer',
    )

  const pageBtn = (active: boolean) =>
    cn(
      'flex h-7 min-w-[28px] items-center justify-center rounded px-1.5 text-[12px] transition-colors select-none cursor-pointer',
      active
        ? 'bg-[#0078d4] text-white font-medium'
        : 'text-[#605e5c] hover:bg-[#edebe9]',
    )

  return (
    <div className="flex flex-wrap items-center justify-between gap-3 border-t border-[#e9e9e7] px-3 py-2.5 bg-[#fafaf9]">
      {/* Left — totals + page size */}
      <div className="flex items-center gap-3 text-[12px] text-[#9b9a97]">
        <span>
          <span className="font-medium text-[#37352f]">{total}</span> items
        </span>
        <div className="flex items-center gap-1">
          <span>Rows:</span>
          <select
            value={pageSize}
            onChange={(e) => onPageChange?.(1, Number(e.target.value))}
            className="h-6 rounded border border-[#e3e2e0] bg-white px-1 text-[12px] text-[#37352f] outline-none focus:border-[#0078d4] cursor-pointer"
          >
            {PAGE_SIZE_OPTIONS.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
        </div>
        <span className="text-[#b9b8b6]">{from}–{to}</span>
      </div>

      {/* Right — navigation */}
      <div className="flex items-center gap-0.5">
        {/* « first */}
        <button type="button" disabled={atFirst} onClick={() => onPageChange?.(1, pageSize)} className={navBtn(atFirst)} title="First page">
          «
        </button>
        {/* ‹ prev */}
        <button type="button" disabled={atFirst} onClick={() => onPageChange?.(page - 1, pageSize)} className={navBtn(atFirst)} title="Previous page">
          ‹
        </button>

        <div className="mx-1 flex items-center gap-0.5">
          {pages.map((p, i) =>
            p === '...' ? (
              <span key={`e-${i}`} className="flex h-7 w-7 items-center justify-center text-[11px] text-[#9b9a97] tracking-widest">
                ···
              </span>
            ) : (
              <button
                key={p}
                type="button"
                onClick={() => onPageChange?.(p as number, pageSize)}
                className={pageBtn(p === page)}
              >
                {p}
              </button>
            ),
          )}
        </div>

        {/* › next */}
        <button type="button" disabled={atLast} onClick={() => onPageChange?.(page + 1, pageSize)} className={navBtn(atLast)} title="Next page">
          ›
        </button>
        {/* » last */}
        <button type="button" disabled={atLast} onClick={() => onPageChange?.(totalPages, pageSize)} className={navBtn(atLast)} title="Last page">
          »
        </button>
      </div>
    </div>
  )
}

// ── DataTable ──────────────────────────────────────────────────────────────────

export function DataTable<T extends object>({
  columns,
  data,
  rowKey,
  loading = false,
  pagination,
  selectable = false,
  className,
  onRowClick,
  onSort,
  onPageChange,
  onSelectionChange,
}: DataTableProps<T>) {
  const rawRows = Array.isArray(data) ? data : []
  const [sort, setSort] = useState<SortState>(null)

  const rows = useMemo(() => {
    if (!sort) return rawRows
    const col = columns.find((c) => c.key === sort.key)
    if (!col) return rawRows
    // Function accessors can't provide raw values — fall back to col.key
    const field = (typeof col.accessor === 'string' ? col.accessor : col.key) as keyof T
    const dir = sort.direction === 'asc' ? 1 : -1
    return [...rawRows].sort((a, b) => {
      const av = a[field]
      const bv = b[field]
      if (av == null && bv == null) return 0
      if (av == null) return dir
      if (bv == null) return -dir
      if (typeof av === 'number' && typeof bv === 'number') return (av - bv) * dir
      const as = String(av)
      const bs = String(bv)
      // Parse as date when the value looks like an ISO string
      const at = Date.parse(as)
      const bt = Date.parse(bs)
      if (!isNaN(at) && !isNaN(bt)) return (at - bt) * dir
      return as.localeCompare(bs) * dir
    })
  }, [rawRows, sort, columns])
  const [selectedKeys, setSelectedKeys] = useState<Set<string>>(new Set())
  const [hoveredCol, setHoveredCol] = useState<string | null>(null)

  const handleSort = useCallback(
    (key: string) => {
      const direction = sort?.key === key && sort.direction === 'asc' ? 'desc' : 'asc'
      setSort({ key, direction })
      onSort?.(key, direction)
    },
    [sort, onSort],
  )

  const toggleRow = useCallback(
    (row: T, key: string) => {
      setSelectedKeys((prev) => {
        const next = new Set(prev)
        next.has(key) ? next.delete(key) : next.add(key)
        onSelectionChange?.(rows.filter((r) => next.has(getKey(r, rowKey))))
        return next
      })
    },
    [rows, rowKey, onSelectionChange],
  )

  const toggleAll = useCallback(() => {
    if (selectedKeys.size === rows.length) {
      setSelectedKeys(new Set())
      onSelectionChange?.([])
    } else {
      const all = new Set(rows.map((r) => getKey(r, rowKey)))
      setSelectedKeys(all)
      onSelectionChange?.(rows)
    }
  }, [rows, rowKey, selectedKeys.size, onSelectionChange])

  const totalPages = pagination ? Math.ceil(pagination.total / pagination.pageSize) : 1
  const allSelected = rows.length > 0 && selectedKeys.size === rows.length
  const colCount = columns.length + (selectable ? 1 : 0)

  return (
    <div className={cn('overflow-hidden rounded border border-[#e3e2e0] bg-white', className)}>
      <div className="overflow-x-auto">
        <table className="w-full text-[13px]" style={{ borderCollapse: 'collapse' }}>
          {/* ── Header ── */}
          <thead>
            <tr className="border-b border-[#e3e2e0] bg-[#f7f6f3]">
              {selectable && (
                <th className="w-9 border-r border-[#e9e9e7] px-3 py-2">
                  <input
                    type="checkbox"
                    checked={allSelected}
                    onChange={toggleAll}
                    className="h-3.5 w-3.5 rounded border-[#c8c6c4] accent-[#0078d4] cursor-pointer"
                  />
                </th>
              )}
              {columns.map((col, colIdx) => (
                <th
                  key={col.key}
                  style={{ width: col.width }}
                  onClick={() => col.sortable && handleSort(col.key)}
                  onMouseEnter={() => col.sortable && setHoveredCol(col.key)}
                  onMouseLeave={() => setHoveredCol(null)}
                  className={cn(
                    'px-3 py-2 text-left text-[11px] font-semibold uppercase tracking-wider whitespace-nowrap select-none transition-colors',
                    sort?.key === col.key ? 'text-[#0078d4]' : 'text-[#9b9a97]',
                    colIdx < columns.length - 1 && 'border-r border-[#e9e9e7]',
                    col.align === 'center' && 'text-center',
                    col.align === 'right' && 'text-right',
                    col.sortable && 'cursor-pointer hover:bg-[#edebe9] hover:text-[#605e5c]',
                  )}
                >
                  <span className="inline-flex items-center gap-1">
                    {col.header}
                    {col.sortable && (
                      <span
                        style={{
                          opacity: sort?.key === col.key || hoveredCol === col.key ? 1 : 0,
                          transition: 'opacity 0.15s',
                        }}
                      >
                        <SortIcon
                          active={sort?.key === col.key}
                          direction={sort?.key === col.key ? sort.direction : null}
                        />
                      </span>
                    )}
                  </span>
                </th>
              ))}
            </tr>
          </thead>

          {/* ── Body ── */}
          <tbody>
            {loading
              ? Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse border-b border-[#e9e9e7]">
                    {selectable && (
                      <td className="border-r border-[#e9e9e7] px-3 py-2.5">
                        <div className="h-3.5 w-3.5 rounded bg-[#f0efed]" />
                      </td>
                    )}
                    {columns.map((col, colIdx) => (
                      <td key={col.key} className={cn('px-3 py-2.5', colIdx < columns.length - 1 && 'border-r border-[#e9e9e7]')}>
                        <div
                          className="h-3.5 rounded bg-[#f0efed]"
                          style={{ width: `${SKELETON_WIDTHS[(i * columns.length + colIdx) % SKELETON_WIDTHS.length]}%` }}
                        />
                      </td>
                    ))}
                  </tr>
                ))
              : rows.length === 0
              ? (
                <tr>
                  <td colSpan={colCount} className="py-16 text-center">
                    <div className="flex flex-col items-center gap-2 text-[#9b9a97]">
                      <svg className="h-10 w-10 opacity-40" fill="none" viewBox="0 0 64 64" stroke="currentColor" strokeWidth={1.5}>
                        <rect x="8" y="16" width="48" height="36" rx="3" />
                        <path d="M8 24h48M20 16v8M44 16v8" />
                      </svg>
                      <span className="text-[13px]">No data</span>
                    </div>
                  </td>
                </tr>
              )
              : rows.map((row, index) => {
                  const key = getKey(row, rowKey)
                  const isSelected = selectedKeys.has(key)
                  return (
                    <tr
                      key={key}
                      onClick={() => onRowClick?.(row, index)}
                      className={cn(
                        'group border-b border-[#e9e9e7] last:border-0 transition-colors',
                        onRowClick && 'cursor-pointer',
                        isSelected
                          ? 'bg-[#e8f4fd] hover:bg-[#d6edf9]'
                          : 'hover:bg-[#f7f6f3]',
                      )}
                    >
                      {selectable && (
                        <td
                          className="border-r border-[#e9e9e7] px-3 py-2.5"
                          onClick={(e) => { e.stopPropagation(); toggleRow(row, key) }}
                        >
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => toggleRow(row, key)}
                            className="h-3.5 w-3.5 rounded border-[#c8c6c4] accent-[#0078d4] cursor-pointer"
                          />
                        </td>
                      )}
                      {columns.map((col, colIdx) => (
                        <td
                          key={col.key}
                          className={cn(
                            'px-3 py-2.5 text-[#37352f]',
                            colIdx < columns.length - 1 && 'border-r border-[#e9e9e7]',
                            col.align === 'center' && 'text-center',
                            col.align === 'right' && 'text-right',
                          )}
                        >
                          {getCellValue(row, col, index)}
                        </td>
                      ))}
                    </tr>
                  )
                })}
          </tbody>
        </table>
      </div>

      {pagination && (
        <TablePagination
          pagination={pagination}
          totalPages={totalPages}
          onPageChange={onPageChange}
        />
      )}
    </div>
  )
}
