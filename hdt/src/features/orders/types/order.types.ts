export interface Order {
  id: string
  userId: string
  status: 'pending' | 'confirmed' | 'shipped' | 'delivered'
  totalAmount: number
  createdAt: string
}

export interface CreateOrderPayload {
  items: { productId: string; quantity: number }[]
}
