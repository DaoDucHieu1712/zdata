# Task.md — Foundation status & conventions

The original brief was to build the reusable list/form infrastructure and wire it to an API.
**That foundation is built and in use.** This file records what exists and how to extend it.
See `AGENTS.md` for the full architecture and coding rules.

## Original brief → status

| Ask | Status | Where |
|---|---|---|
| Generic `DataTable<T>` (column config + data, emits events) | ✅ Done | `components/common/data-table.tsx` (`ColumnDef<T>`, `onRowClick`/`onSort`/`onPageChange`/`onSelectionChange`, sort + skeleton + pagination) |
| `SearchPanel<T>` (RHF + Zod, grid system, generic) | ✅ Done | `components/common/search-panel.tsx` (config-driven `fields`, `cols`/`colSpan` grid, `onSearch`/`onReset`/`onChange`) |
| Feature `store.ts` combining DataTable + SearchPanel | ✅ Done | `lib/create-list-store.ts` factory + per-feature `store.ts`; glued by `hooks/use-list-page.ts` |
| Common UI form inputs for SearchPanel | ✅ Done | `components/ui/`: `input`, `select` (single + multi), `textarea`, `datetime-input`, `radio`, `checkbox`, `range-input` |
| Axios + TanStack Query, base `https://localhost:9000` | ✅ Done | `lib/api-client.ts` (baseURL from `NEXT_PUBLIC_API_URL`, default `https://localhost:9000`), `lib/query-client.ts`, `app/providers.tsx` |

> Configure the API base with `NEXT_PUBLIC_API_URL` (validated in `config/env.ts`).

## Features already wired to this infrastructure

`blog`, `notes`, `orders`, `vocab` (list/CRUD), plus `workflow` and `storyboard`
(React Flow canvases via `@xyflow/react`). Each follows the `features/{x}` layout in `AGENTS.md`.

## How to build a new list screen

1. `types/` — define `{Entity}` and `{Entity}SearchParams`.
2. `schemas/` — Zod `…SearchSchema` (+ create/update schemas).
3. `api/fetchers.ts` — async funcs calling `apiClient`.
4. `api/queries.ts` — `useQuery` hooks + keys via `createQueryKeys(namespace)`.
5. `api/mutations.ts` — `useMutation` hooks, invalidate keys `onSuccess`.
6. `store.ts` — `createListStore<{Entity}SearchParams>({})`.
7. `index.ts` — barrel-export the public API.
8. Component — `useListPage(useStore, useQueryHook)` → feed a `SearchPanel` (`onSearch={setSearchParams}`)
   and a `DataTable` (`pagination`, `onPageChange={(page, pageSize) => setPagination({ page, pageSize })}`).

See the full worked "orders" example in `AGENTS.md`.

## Definition of Done

- No `any`; feature types in `types/`; public API via `index.ts` barrel.
- Reuse `DataTable` / `SearchPanel` / `createListStore` / `useListPage` / `createQueryKeys` — don't rebuild them.
- Tailwind + `cn()`; grid layouts; one component per kebab-case file.
- `npm run lint` and `tsc` clean.
