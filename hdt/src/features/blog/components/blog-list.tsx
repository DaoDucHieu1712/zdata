'use client'

import { useListPage } from '@/hooks/use-list-page'
import { DataTable } from '@/components/common/data-table'
import { SearchPanel } from '@/components/common/search-panel'
import { StatusBadge } from '@/components/common/status-badge'
import { TagList } from '@/components/common/tag-list'
import { BulkActionBar } from '@/components/common/bulk-action-bar'
import { useBlogStore } from '../store'
import { useBlogs } from '../api/queries'
import { useDeleteBlog } from '../api/mutations'
import { blogSearchSchema } from '../schemas/blog.schema'
import type { Blog } from '../types/blog.types'
import type { ColumnDef } from '@/components/common/data-table'
import type { SearchFieldConfig } from '@/components/common/search-panel'
import type { BlogSearchInput } from '../schemas/blog.schema'

// ── Column definitions ─────────────────────────────────────────────────────────

const COLUMNS: ColumnDef<Blog>[] = [
  { key: 'title', header: 'Title', accessor: 'title', sortable: true },
  { key: 'author', header: 'Author', accessor: 'author', width: '140px' },
  {
    key: 'status',
    header: 'Status',
    width: '110px',
    align: 'center',
    accessor: (row) => <StatusBadge status={row.status} />,
  },
  {
    key: 'tags',
    header: 'Tags',
    accessor: (row) => <TagList tags={row.tags} />,
  },
  {
    key: 'createdAt',
    header: 'Created',
    width: '110px',
    sortable: true,
    align: 'right',
    accessor: (row) => new Date(row.createdAt).toLocaleDateString(),
  },
]

// ── Search field config ────────────────────────────────────────────────────────

const SEARCH_FIELDS: SearchFieldConfig[] = [
  { type: 'text', name: 'title', label: 'Title', placeholder: 'Search by title…' },
  { type: 'text', name: 'author', label: 'Author', placeholder: 'Search by author…' },
  {
    type: 'select',
    name: 'status',
    label: 'Status',
    placeholder: 'All statuses',
    options: [
      { label: 'Draft', value: 'draft' },
      { label: 'Published', value: 'published' },
      { label: 'Archived', value: 'archived' },
    ],
  },
  {
    type: 'select',
    name: 'tags',
    label: 'Tags',
    multiple: true,
    colSpan: 2,
    options: [
      { label: 'React', value: 'react' },
      { label: 'TypeScript', value: 'typescript' },
      { label: 'Next.js', value: 'nextjs' },
      { label: 'Node.js', value: 'nodejs' },
      { label: 'CSS', value: 'css' },
    ],
  },
  { type: 'date', name: 'dateFrom', label: 'From date' },
  { type: 'date', name: 'dateTo', label: 'To date' },
]

const DEFAULT_SEARCH: BlogSearchInput = {
  title: '',
  author: '',
  status: '',
  tags: [],
  dateFrom: '',
  dateTo: '',
}

// ── Component ──────────────────────────────────────────────────────────────────

export function BlogList() {
  const { data, isLoading, pagination, selectedIds, setSearchParams, setPagination, setSelectedIds } =
    useListPage(useBlogStore, useBlogs)

  const { mutate: deleteBlog } = useDeleteBlog()

  return (
    <div className="flex flex-col gap-4">
      <SearchPanel<BlogSearchInput>
        fields={SEARCH_FIELDS}
        schema={blogSearchSchema}
        defaultValues={DEFAULT_SEARCH}
        cols={3}
        loading={isLoading}
        onSearch={setSearchParams}
        onReset={() => setSearchParams({})}
      />

      <BulkActionBar
        count={selectedIds.length}
        entityLabel="post"
        actions={[{
          label: 'Delete selected',
          variant: 'danger',
          onClick: () => { selectedIds.forEach((id) => deleteBlog(id)); setSelectedIds([]) },
        }]}
        onClear={() => setSelectedIds([])}
      />

      <DataTable<Blog>
        columns={COLUMNS}
        data={data}
        rowKey="id"
        loading={isLoading}
        selectable
        pagination={pagination}
        onSelectionChange={(rows) => setSelectedIds(rows.map((r) => r.id))}
        onPageChange={(page, pageSize) => setPagination({ page, pageSize })}
        onSort={(key, direction) => console.log('sort →', key, direction)}
        onRowClick={(row) => console.log('open →', row.id)}
      />
    </div>
  )
}
