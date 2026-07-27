export interface Blog {
  id: string
  title: string
  slug: string
  excerpt: string
  content: string
  author: string
  status: 'draft' | 'published' | 'archived'
  tags: string[]
  coverImage?: string
  createdAt: string
  updatedAt: string
}

export interface CreateBlogPayload {
  title: string
  excerpt: string
  content: string
  author: string
  status: 'draft' | 'published'
  tags: string[]
}

export interface UpdateBlogPayload extends Partial<CreateBlogPayload> {
  id: string
}
