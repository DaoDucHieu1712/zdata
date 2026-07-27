'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import type { ReactNode } from 'react'
import { cn } from '@/lib/utils/cn'
import { ROUTES } from '@/config/routes'

interface NavItem {
  label: string
  href: string
  icon: ReactNode
}

const NAV_ITEMS: NavItem[] = [
  {
    label: 'Vocabulary',
    href: ROUTES.VOCAB,
    icon: (
      <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.042A8.967 8.967 0 0 0 6 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 0 1 6 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 0 1 6-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0 0 18 18a8.967 8.967 0 0 0-6 2.292m0-14.25v14.25" />
      </svg>
    ),
  },
  {
    label: 'Notes',
    href: ROUTES.NOTES,
    icon: (
      <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z" />
      </svg>
    ),
  },
  {
    label: 'Blog',
    href: ROUTES.BLOG,
    icon: (
      <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z" />
      </svg>
    ),
  },
  {
    label: 'Workflow',
    href: ROUTES.WORKFLOW,
    icon: (
      <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M6 6.878V6a2.25 2.25 0 0 1 2.25-2.25h7.5A2.25 2.25 0 0 1 18 6v.878m-12 0c.235-.083.487-.128.75-.128h10.5c.263 0 .515.045.75.128m-12 0A2.25 2.25 0 0 0 4.5 9v.878m13.5-3A2.25 2.25 0 0 1 19.5 9v.878m0 0a2.246 2.246 0 0 0-.75-.128H5.25c-.263 0-.515.045-.75.128m15 0A2.25 2.25 0 0 1 21 12v6a2.25 2.25 0 0 1-2.25 2.25H5.25A2.25 2.25 0 0 1 3 18v-6c0-.98.626-1.813 1.5-2.122" />
      </svg>
    ),
  },
  {
    label: 'Storyboard',
    href: ROUTES.STORYBOARD,
    icon: (
      <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M3.375 19.5h17.25m-17.25 0a1.125 1.125 0 0 1-1.125-1.125M3.375 19.5h7.5c.621 0 1.125-.504 1.125-1.125m-9.75 0V5.625m0 12.75v-1.5c0-.621.504-1.125 1.125-1.125m18.375 2.625V5.625m0 12.75c0 .621-.504 1.125-1.125 1.125m1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125m0 3.75h-7.5A1.125 1.125 0 0 1 12 18.375m9.75-12.75c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125m19.5 0v1.5c0 .621-.504 1.125-1.125 1.125M2.25 5.625v1.5c0 .621.504 1.125 1.125 1.125m0 0h17.25m-17.25 0h7.5c.621 0 1.125.504 1.125 1.125M3.375 8.25c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125m0 0h7.5" />
      </svg>
    ),
  },
  {
    label: 'Orders',
    href: ROUTES.ORDERS,
    icon: (
      <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 10.5V6a3.75 3.75 0 1 0-7.5 0v4.5m11.356-1.993 1.263 12c.07.665-.45 1.243-1.119 1.243H4.25a1.125 1.125 0 0 1-1.12-1.243l1.264-12A1.125 1.125 0 0 1 5.513 7.5h12.974c.576 0 1.059.435 1.119 1.007Z" />
      </svg>
    ),
  },
]

export function AppShell({ children }: { children: ReactNode }) {
  const pathname = usePathname()
  const isFullBleed =
    pathname.startsWith('/notes') ||
    pathname.startsWith('/workflow') ||
    pathname.startsWith('/storyboard')

  return (
    <div className="flex h-full flex-col">
      {/* ── Top bar ─────────────────────────────────────────────────────────────── */}
      <header className="flex h-12 shrink-0 items-center gap-3 bg-[#0078d4] px-4 shadow-sm z-30">
        {/* Logo mark */}
        <div className="flex items-center gap-2.5 select-none">
          <div className="flex h-7 w-7 items-center justify-center rounded bg-white/25 text-xs font-bold text-white">
            H
          </div>
          <span className="text-sm font-semibold text-white tracking-wide">HDT</span>
        </div>

        {/* Search pill */}
        <div className="mx-4 flex-1 max-w-sm">
          <div className="flex h-7 items-center gap-2 rounded bg-white/15 px-3 text-sm text-white/75 cursor-text hover:bg-white/20 transition-colors">
            <svg className="h-3.5 w-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
            </svg>
            <span className="text-[13px]">Search</span>
          </div>
        </div>

        {/* Right actions */}
        <div className="ml-auto flex items-center gap-1.5">
          <button
            type="button"
            className="flex h-8 w-8 items-center justify-center rounded-full bg-white/20 text-sm font-semibold text-white hover:bg-white/30 transition-colors"
            title="Account"
          >
            H
          </button>
        </div>
      </header>

      <div className="flex flex-1 overflow-hidden">
        {/* ── Sidebar ───────────────────────────────────────────────────────────── */}
        <aside className="flex w-[220px] shrink-0 flex-col border-r border-[#e1dfdd] bg-[#f3f2f1] overflow-y-auto">
          <nav className="flex flex-col gap-0.5 p-2 pt-3">
            {NAV_ITEMS.map((item) => {
              const isActive = pathname === item.href || pathname.startsWith(item.href + '/')
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    'flex items-center gap-2.5 rounded px-3 py-[7px] text-[13.5px] font-medium transition-colors select-none',
                    isActive
                      ? 'bg-white text-[#0078d4] shadow-[0_1px_3px_rgba(0,0,0,0.1)]'
                      : 'text-[#323130] hover:bg-[#e8e6e3] hover:text-[#201f1e]',
                  )}
                >
                  <span className={cn('shrink-0', isActive ? 'text-[#0078d4]' : 'text-[#605e5c]')}>
                    {item.icon}
                  </span>
                  {item.label}
                </Link>
              )
            })}
          </nav>
        </aside>

        {/* ── Content ───────────────────────────────────────────────────────────── */}
        <main className={cn('flex-1 overflow-hidden bg-white', !isFullBleed && 'overflow-y-auto')}>
          {isFullBleed ? children : (
            <div className="mx-auto max-w-screen-xl overflow-y-auto h-full px-8 py-6">
              {children}
            </div>
          )}
        </main>
      </div>
    </div>
  )
}
