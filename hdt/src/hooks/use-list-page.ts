'use client'

import type { UseQueryResult } from '@tanstack/react-query'
import type { ListState } from '@/lib/create-list-store'

/**
 * Combines a feature list store with its TanStack Query hook.
 * Eliminates the repetitive destructure + query wiring in every list component.
 *
 * Usage:
 *   const { data, isLoading, pagination, selectedIds, setSearchParams, ... } =
 *     useListPage(useBlogStore, useBlogs)
 */
export function useListPage<T, TParams extends object>(
  store: () => ListState<TParams>,
  queryHook: (params: TParams) => UseQueryResult<T[]>,
) {
  const state = store()
  const { data, isLoading, isError, error } = queryHook(state.searchParams)
  return {
    ...state,
    data: data ?? [],
    isLoading,
    isError,
    error,
  }
}
