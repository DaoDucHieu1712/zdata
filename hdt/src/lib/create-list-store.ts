import { create } from 'zustand'
import type { PaginationState } from '@/components/common/data-table'

export interface ListState<TParams extends object> {
  searchParams: TParams
  pagination: PaginationState
  selectedIds: string[]
  setSearchParams: (params: TParams) => void
  setPagination: (p: Partial<PaginationState>) => void
  setSelectedIds: (ids: string[]) => void
  reset: () => void
}

const DEFAULT_PAGINATION: PaginationState = { page: 1, pageSize: 10, total: 0 }

export function createListStore<TParams extends object>(initialParams: TParams) {
  return create<ListState<TParams>>((set) => ({
    searchParams: initialParams,
    pagination: DEFAULT_PAGINATION,
    selectedIds: [],
    setSearchParams: (params) =>
      set({ searchParams: params, pagination: { ...DEFAULT_PAGINATION } }),
    setPagination: (p) =>
      set((s) => ({ pagination: { ...s.pagination, ...p } })),
    setSelectedIds: (ids) => set({ selectedIds: ids }),
    reset: () =>
      set({ searchParams: initialParams, pagination: DEFAULT_PAGINATION, selectedIds: [] }),
  }))
}
