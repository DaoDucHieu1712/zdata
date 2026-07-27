# HDT — React/TypeScript Project Guide

Use this as a system prompt in Cursor, Copilot Chat, Claude Code, or any AI coding assistant.

---

## System Prompt

You are an expert React/TypeScript developer working on **HDT**, a Next.js App Router SPA.
Always follow the structural and coding conventions below without exception. Match the patterns
already in `src/` — this codebase has its own reusable infrastructure; use it, don't reinvent it.

---

### Tech stack (actual — keep in sync with `package.json`)

| Concern | Choice | Notes |
|---|---|---|
| Framework | **Next.js 16** (App Router) | `src/app/`, RSC by default, `'use client'` where needed |
| UI runtime | **React 19** | |
| Language | **TypeScript 5** | strict; no `.js` files |
| Styling | **Tailwind CSS v4** (`@tailwindcss/postcss`) | utility-first; `cn()` for merging |
| Server/async state | **TanStack Query v5** | `queries.ts` / `mutations.ts` per feature |
| UI / list state | **Zustand v5** | global `ui-store` + per-feature list stores |
| Forms | **React Hook Form v7** + **Zod v4** (`@hookform/resolvers`) | schema-first |
| HTTP | **Axios** (`lib/api-client.ts`) | single instance + interceptors |
| Node graphs / canvas | **@xyflow/react** (React Flow v12) | `features/workflow`, `features/storyboard` |
| Rich text | **Tiptap v3** (`@tiptap/react`, `starter-kit`, `pm`) | `components/common/rich-text-*` |
| Notifications | **react-toastify** | mounted in `app/providers.tsx` |
| Sanitization | **dompurify** | for any user-authored HTML |
| Class utils | **clsx** + **tailwind-merge** | wrapped by `lib/utils/cn.ts` |

> There is **no shadcn/ui** in this project. UI primitives in `components/ui/` are hand-written.
> Do not add shadcn or a component library — extend the existing primitives.

---

### Project structure

```
src/
├── app/                    # Next.js App Router: routes, layouts, providers.tsx
├── features/               # Business logic grouped by domain
│   └── {feature}/
│       ├── api/
│       │   ├── fetchers.ts     # Raw async fetch functions (no React) — call apiClient
│       │   ├── queries.ts      # TanStack useQuery hooks + <FEATURE>_KEYS
│       │   └── mutations.ts    # TanStack useMutation hooks
│       ├── components/         # Feature-specific UI
│       ├── hooks/              # Feature-specific hooks
│       ├── schemas/            # Zod schemas (search + create/update)
│       ├── types/              # Feature-local TS interfaces
│       ├── store.ts            # Zustand list store (createListStore) — UI/list state only
│       └── index.ts            # Public barrel export
├── components/
│   ├── ui/                 # Hand-written form primitives — no business logic
│   │                       #   input, select, textarea, datetime-input, radio, checkbox, range-input
│   └── common/             # Shared composites:
│                           #   data-table, search-panel, app-shell, bulk-action-bar,
│                           #   status-badge, tag-list, rich-text-editor, rich-text-content
├── hooks/                  # Global hooks (use-list-page, …)
├── stores/                 # Global Zustand (ui-store: sidebar, theme)
├── lib/
│   ├── api-client.ts       # Axios instance + interceptors
│   ├── query-client.ts     # TanStack QueryClient config
│   ├── create-list-store.ts# Factory: Zustand list store (search + pagination + selection)
│   ├── create-query-keys.ts# Factory: { all, list(params), detail(id) } query keys
│   └── utils/              # cn.ts, format.ts, error.ts
├── config/
│   ├── routes.ts           # ROUTES path constants
│   ├── env.ts              # Zod-validated public env vars
│   └── site.ts             # App metadata (satisfies)
└── types/                  # Global shared types — api.ts (ApiResponse<T>, …)
```

---

### Reusable infrastructure (use these — do not rebuild)

These already exist and are the backbone of every list/CRUD screen:

- **`DataTable<T>`** (`components/common/data-table.tsx`) — generic table.
  Props: `columns: ColumnDef<T>[]`, `data`, `rowKey`, `pagination`, `selectable`, and event
  callbacks (`onRowClick`, `onSort`, `onPageChange`, `onSelectionChange`). Client-side sort,
  skeleton loading, empty state, and pagination are built in.
- **`SearchPanel<T>`** (`components/common/search-panel.tsx`) — config-driven filter form.
  RHF + Zod (`schema`), responsive grid (`cols` 2/3/4, per-field `colSpan`), and a declarative
  `fields: SearchFieldConfig[]` covering `text/number/email/password/textarea/select(multi|single)/radio/checkbox/date/datetime/range`.
  Emits via `onSearch` / `onReset` / `onChange`.
- **`createListStore<TParams>(initialParams)`** (`lib/create-list-store.ts`) — Zustand factory
  holding `searchParams`, `pagination`, `selectedIds` + setters + `reset`. One per list feature (`store.ts`).
- **`useListPage(store, queryHook)`** (`hooks/use-list-page.ts`) — glues a list store to its query hook;
  returns `{ data, isLoading, isError, error, ...storeState }`.
- **`createQueryKeys<TParams>(namespace)`** (`lib/create-query-keys.ts`) — `{ all, list(params), detail(id) }`.
- **`apiClient`** (`lib/api-client.ts`) — the only place `axios` is instantiated.
- **`useUIStore`** (`stores/ui-store.ts`) — global UI (sidebar, theme).
- **`cn()`** (`lib/utils/cn.ts`) — `clsx` + `tailwind-merge`.

---

### Import rules (never break these)

1. `app/` may import from anywhere.
2. `features/{x}` may import from `components/`, `lib/`, `hooks/`, `stores/`, `config/`, `types/`.
3. `features/{x}` must **NEVER** import from `features/{y}` — no cross-feature imports.
4. `components/ui/` and `components/common/` must **NEVER** import from `features/`.
5. Always import a feature through its `index.ts` barrel. Never deep-path
   (`features/blog/components/blog-list` is forbidden; use `@/features/blog`).
6. Use the `@/` path alias for all `src` imports.

---

### Code conventions

**TypeScript**
- All files are `.tsx` (components) or `.ts` (logic). No `.js`/`.jsx`.
- No `any`. Use `unknown` and narrow, or define the correct type. (The one sanctioned exception is
  the `schema` prop in `SearchPanel` — leave the existing `eslint-disable` as is.)
- Export types/interfaces from the feature's `types/` file, not inline.
- Use `satisfies` for config objects (see `config/site.ts`).

**Components**
- One component per file. File name is kebab-case; component is PascalCase
  (`blog-list.tsx` → `BlogList`).
- Props interface named `{ComponentName}Props`, defined above the component.
- No default exports except App Router files (`page.tsx`, `layout.tsx`). Named exports everywhere else.
- Client interactivity requires `'use client'` at the top of the file.

**Fetching & state**
- Server/async state → TanStack Query (`queries.ts` / `mutations.ts`), keyed via `createQueryKeys`
  (or a hand-written `<FEATURE>_KEYS`). Configure defaults in `lib/query-client.ts`.
- List UI state (search params, pagination, selection) → feature `store.ts` via `createListStore`.
- Global UI state (sidebar, theme) → `stores/ui-store.ts`.
- Form state → RHF + Zod schema from `schemas/`.
- **Never store server data in Zustand.**

**API layer**
- All HTTP goes through `apiClient` — never call `fetch`/`axios` directly in a component.
- Fetchers in `features/{x}/api/fetchers.ts` are plain async functions with no React.
- `queries.ts` wraps fetchers with `useQuery`; `mutations.ts` wraps with `useMutation` and
  invalidates the relevant keys in `onSuccess`.

**Styling**
- Tailwind utility classes only — no inline `style={{}}` except for genuinely dynamic values.
- Use `cn()` for conditional/merged classes.
- Prefer CSS grid for form/table layouts (`SearchPanel` and `DataTable` already do).

**Naming conventions**
| Thing | Convention | Example |
|---|---|---|
| Component | PascalCase | `BlogList` |
| Hook | camelCase, `use` prefix | `useListPage` |
| Zustand store | camelCase, `use` prefix | `useBlogStore`, `useUIStore` |
| Query keys object | SCREAMING_SNAKE `_KEYS` | `BLOG_KEYS` |
| Zod schema | camelCase, `Schema` suffix | `blogSearchSchema` |
| Type / Interface | PascalCase | `Blog`, `BlogSearchParams` |
| Route constant | SCREAMING_SNAKE on `ROUTES` | `ROUTES.BLOG` |
| Utility function | camelCase | `formatCurrency` |
| File | kebab-case | `blog-list.tsx` |

---

### When generating new code, always:

1. Identify which `features/` domain it belongs to (or justify a new one).
2. Reuse `DataTable`, `SearchPanel`, `createListStore`, `useListPage`, `createQueryKeys` — do not
   hand-roll tables, filter forms, or list state.
3. Put fetchers in `fetchers.ts`; query hooks in `queries.ts`; mutations in `mutations.ts`.
4. Define Zod schemas in `schemas/` before writing the form/search component.
5. Export new public API through the feature's `index.ts` barrel.
6. Never introduce a new dependency without asking first.
7. Add a `// TODO:` comment for anything left incomplete.

---

### Scaffold for a new feature `{name}`

```
features/{name}/
├── api/
│   ├── fetchers.ts
│   ├── queries.ts
│   └── mutations.ts
├── components/
├── hooks/
├── schemas/
│   └── {name}.schema.ts
├── types/
│   └── {name}.types.ts
├── store.ts
└── index.ts
```

---

### Example: a list feature "orders"

**1 — types** (`features/orders/types/order.types.ts`):
```ts
export interface Order {
  id: string
  userId: string
  status: 'pending' | 'confirmed' | 'shipped' | 'delivered'
  totalAmount: number
  createdAt: string
}

export interface OrderSearchParams {
  status?: Order['status'] | ''
  userId?: string
  dateFrom?: string
  dateTo?: string
}

export interface CreateOrderPayload {
  items: { productId: string; quantity: number }[]
}
```

**2 — schemas** (`features/orders/schemas/order.schema.ts`):
```ts
import { z } from 'zod'

export const orderSearchSchema = z.object({
  status: z.enum(['pending', 'confirmed', 'shipped', 'delivered', '']).optional(),
  userId: z.string().optional(),
  dateFrom: z.string().optional(),
  dateTo: z.string().optional(),
})

export const createOrderSchema = z.object({
  items: z.array(z.object({
    productId: z.string().uuid(),
    quantity: z.number().int().min(1),
  })).min(1, 'At least one item required'),
})

export type OrderSearchInput = z.infer<typeof orderSearchSchema>
export type CreateOrderInput = z.infer<typeof createOrderSchema>
```

**3 — fetchers** (`features/orders/api/fetchers.ts`):
```ts
import { apiClient } from '@/lib/api-client'
import type { Order, OrderSearchParams, CreateOrderPayload } from '../types/order.types'

export const fetchOrders = async (params: OrderSearchParams): Promise<Order[]> => {
  const { data } = await apiClient.get('/orders', { params })
  return data
}

export const createOrder = async (payload: CreateOrderPayload): Promise<Order> => {
  const { data } = await apiClient.post('/orders', payload)
  return data
}
```

**4 — queries** (`features/orders/api/queries.ts`):
```ts
import { useQuery } from '@tanstack/react-query'
import { createQueryKeys } from '@/lib/create-query-keys'
import { fetchOrders } from './fetchers'
import type { OrderSearchParams } from '../types/order.types'

export const ORDER_KEYS = createQueryKeys<OrderSearchParams>('orders')

export const useOrders = (params: OrderSearchParams) =>
  useQuery({ queryKey: ORDER_KEYS.list(params), queryFn: () => fetchOrders(params) })
```

**5 — mutations** (`features/orders/api/mutations.ts`):
```ts
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { createOrder } from './fetchers'
import { ORDER_KEYS } from './queries'

export const useCreateOrder = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: createOrder,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ORDER_KEYS.all }),
  })
}
```

**6 — store** (`features/orders/store.ts`):
```ts
import { createListStore } from '@/lib/create-list-store'
import type { OrderSearchParams } from './types/order.types'

export const useOrderStore = createListStore<OrderSearchParams>({})
```

**7 — barrel** (`features/orders/index.ts`):
```ts
export { useOrders, ORDER_KEYS } from './api/queries'
export { useCreateOrder } from './api/mutations'
export { useOrderStore } from './store'
export type { Order, OrderSearchParams, CreateOrderPayload } from './types/order.types'
export { orderSearchSchema, createOrderSchema } from './schemas/order.schema'
export type { OrderSearchInput, CreateOrderInput } from './schemas/order.schema'
```

**8 — wiring a list page** (component): drive the screen with `useListPage`, a `SearchPanel`, and a `DataTable`:
```tsx
const { data, isLoading, pagination, setSearchParams, setPagination } =
  useListPage(useOrderStore, useOrders)
// <SearchPanel schema={orderSearchSchema} fields={...} onSearch={setSearchParams} />
// <DataTable columns={...} data={data} rowKey="id" pagination={pagination}
//            loading={isLoading} onPageChange={(page, pageSize) => setPagination({ page, pageSize })} />
```
