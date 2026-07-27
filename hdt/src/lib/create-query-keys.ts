export function createQueryKeys<TParams>(namespace: string) {
  return {
    all: [namespace] as const,
    list: (params?: TParams) => [namespace, 'list', params] as const,
    detail: (id: string) => [namespace, id] as const,
  }
}
