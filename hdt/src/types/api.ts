export interface ApiResponse<T> {
  success: boolean
  statusCode: number
  message: string
  errors: unknown | null
  data: T
  timestamp: string
}

export interface PagedResult<T> {
  items: T[]
  pageIndex: number
  pageSize: number
  totalCount: number
  totalPages: number
  hasNextPage: boolean
  hasPreviousPage: boolean
}

/** @deprecated Use ApiResponse + PagedResult instead */
export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  pageSize: number
}

export interface ApiError {
  message: string
  code: string
  statusCode: number
}
