import axios from 'axios'

export const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL ?? 'https://localhost:9000',
  headers: { 'Content-Type': 'application/json' },
})

apiClient.interceptors.request.use((config) => {
  // Strip null/undefined query params so they're never sent as the string "null"
  if (config.params) {
    config.params = Object.fromEntries(
      Object.entries(config.params as Record<string, unknown>).filter(
        ([, v]) => v !== null && v !== undefined,
      ),
    )
  }
  return config
})

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    // TODO: handle 401 redirect, toast errors, etc.
    return Promise.reject(error)
  },
)
