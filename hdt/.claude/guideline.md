# Project Guideline

Reference alongside `AGENTS.md` for day-to-day development.

---

## Adding a new feature — checklist

```
src/features/{name}/
├── api/
│   ├── fetchers.ts     ← 1. plain async functions, no hooks
│   ├── queries.ts      ← 2. useQuery hooks + query key factory
│   └── mutations.ts    ← 3. useMutation hooks, invalidate on success
├── schemas/
│   └── {name}.schema.ts  ← 4. Zod schemas first, types inferred from them
├── types/
│   └── {name}.types.ts   ← 5. interfaces that can't be inferred from Zod
├── components/
│   └── {name}-list.tsx   ← 6. compose DataTable + SearchPanel here
├── store.ts            ← 7. Zustand — UI state only (search params, pagination, selection)
└── index.ts            ← 8. barrel: export everything public, nothing private
```

Then add a route constant in `src/config/routes.ts` and a page at `src/app/{name}/page.tsx`.

---

## DataTable\<T\>

```tsx
import { DataTable } from '@/components/common/data-table'
import type { ColumnDef, PaginationState } from '@/components/common/data-table'

// 1. Define columns outside the component (stable reference)
const COLUMNS: ColumnDef<Blog>[] = [
  { key: 'title',  header: 'Title',  accessor: 'title', sortable: true },
  { key: 'status', header: 'Status', width: '110px', align: 'center',
    accessor: (row) => <Badge>{row.status}</Badge> },   // custom render
]

// 2. Use inside a component
<DataTable<Blog>
  columns={COLUMNS}
  data={blogs}          // Blog[]
  rowKey="id"           // keyof Blog  OR  (row) => string
  loading={isLoading}
  selectable            // adds checkbox column
  pagination={pagination}                                // PaginationState
  onRowClick={(row, index) => router.push(`/blog/${row.id}`)}
  onSort={(key, dir) => /* update sort in store */}
  onPageChange={(page, size) => setPagination({ page, pageSize: size })}
  onSelectionChange={(rows) => setSelectedIds(rows.map(r => r.id))}
/>
```

**ColumnDef\<T\> options**

| Prop | Type | Description |
|---|---|---|
| `key` | `string` | Unique identifier, passed to `onSort` |
| `header` | `string \| ReactNode` | Column heading |
| `accessor` | `keyof T \| (row: T) => ReactNode` | Cell value or custom renderer |
| `width` | `string` | e.g. `'120px'`, `'10%'` |
| `sortable` | `boolean` | Shows sort arrows, calls `onSort` |
| `align` | `'left' \| 'center' \| 'right'` | Text alignment |

---

## SearchPanel\<T\>

```tsx
import { SearchPanel } from '@/components/common/search-panel'
import type { SearchFieldConfig } from '@/components/common/search-panel'

// 1. Define fields outside the component
const FIELDS: SearchFieldConfig[] = [
  { type: 'text',   name: 'title',  label: 'Title',  placeholder: 'Search…' },
  { type: 'select', name: 'status', label: 'Status',
    options: [{ label: 'Draft', value: 'draft' }, { label: 'Published', value: 'published' }] },
  { type: 'select', name: 'tags', label: 'Tags', multiple: true, colSpan: 2,
    options: [{ label: 'React', value: 'react' }] },
  { type: 'date',   name: 'dateFrom', label: 'From' },
  { type: 'date',   name: 'dateTo',   label: 'To' },
]

// 2. Use with your Zod schema
<SearchPanel<BlogSearchInput>
  fields={FIELDS}
  schema={blogSearchSchema}       // any Zod schema — resolver wired internally
  defaultValues={DEFAULT_SEARCH}
  cols={3}                        // 2 | 3 | 4  grid columns
  loading={isLoading}
  onSearch={(values) => setSearchParams(values)}   // called on valid submit
  onReset={() => setSearchParams({})}              // called on Reset button
/>
```

**SearchFieldConfig — supported types**

| `type` | Extra props | Component used |
|---|---|---|
| `'text' \| 'number' \| 'email' \| 'password'` | — | `Input` |
| `'textarea'` | `rows?: number` | `Textarea` |
| `'select'` | `options`, `multiple?: boolean` | `Select` |
| `'radio'` | `options`, `direction?: 'horizontal \| vertical'` | `RadioGroup` |
| `'checkbox'` | — | `Checkbox` |
| `'date' \| 'datetime'` | — | `DatetimeInput` |
| `'range'` | `min`, `max`, `step`, `valueSuffix` | `RangeInput` |

Every field also accepts `colSpan?: 1 | 2 | 3 | 4` and `disabled?: boolean`.

---

## Feature store pattern

The store holds **only UI state** — search params, pagination, selected rows.
Server data always lives in TanStack Query cache.

```ts
// store.ts
import { create } from 'zustand'
import type { PaginationState } from '@/components/common/data-table'

export interface BlogSearchParams { title?: string; status?: string }

interface BlogUIStore {
  searchParams: BlogSearchParams
  pagination: PaginationState
  selectedIds: string[]
  setSearchParams: (p: BlogSearchParams) => void   // resets to page 1
  setPagination:   (p: Partial<PaginationState>) => void
  setSelectedIds:  (ids: string[]) => void
  reset: () => void
}
```

Wire it with a query hook in the component:
```tsx
const { searchParams, pagination, setSearchParams, setPagination } = useBlogStore()
const { data, isLoading } = useBlogs(searchParams)   // re-fetches when params change
```

---

## API layer rules

- All requests go through `src/lib/api-client.ts` (Axios, base URL `https://localhost:9000`).
- Fetchers are plain `async` functions — no React hooks, no UI side-effects.
- Query hooks (`queries.ts`) wrap fetchers with `useQuery` and a typed key factory.
- Mutation hooks (`mutations.ts`) wrap fetchers with `useMutation` and call
  `queryClient.invalidateQueries` on success to keep the cache fresh.

```ts
// Query key factory — always use this for invalidation
export const BLOG_KEYS = {
  all:    ['blogs'] as const,
  list:   (params?: BlogSearchParams) => ['blogs', 'list', params] as const,
  detail: (id: string)               => ['blogs', id]              as const,
}
```

---

## Import rules (never break)

1. `app/` → can import from anywhere.
2. `features/{x}` → can import from `components/`, `lib/`, `hooks/`, `config/`, `types/`.
3. `features/{x}` → **must NOT** import from `features/{y}`.
4. `components/ui/` and `components/common/` → **must NOT** import from `features/` or `stores/`.
5. Always import a feature through its `index.ts` — never deep-import.

```ts
// correct
import { BlogList, useBlogs } from '@/features/blog'

// wrong — deep path
import { BlogList } from '@/features/blog/components/blog-list'
```

---

## UI components quick reference

All components in `src/components/ui/` are `forwardRef`-wrapped and RHF-compatible.

```tsx
// Standalone usage
<Input label="Title" error={errors.title?.message} {...register('title')} />
<Select label="Status" options={statusOptions} value={val} onChange={setVal} />
<Select label="Tags" multiple options={tagOptions} value={tags} onChange={setTags} />
<Textarea label="Content" rows={5} {...register('content')} />
<DatetimeInput label="Publish date" type="datetime-local" {...register('publishedAt')} />
<RadioGroup label="Visibility" options={visibilityOptions} value={val} onChange={setVal} />
<Checkbox label="Send notification" checked={notify} onChange={setNotify} />
<RangeInput label="Priority" min={1} max={10} valueSuffix="%" {...register('priority')} />
```
