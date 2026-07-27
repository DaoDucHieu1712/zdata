'use client'

import { forwardRef, useEffect, useRef, useState } from 'react'
import { cn } from '@/lib/utils/cn'

export interface SelectOption {
  label: string
  value: string
  disabled?: boolean
}

// ── Single select ──────────────────────────────────────────────────────────────

export interface SingleSelectProps {
  name?: string
  label?: string
  options: SelectOption[]
  value?: string
  onChange?: (value: string) => void
  onBlur?: () => void
  placeholder?: string
  error?: string
  disabled?: boolean
  className?: string
  multiple?: false
}

// ── Multi select ───────────────────────────────────────────────────────────────

export interface MultiSelectProps {
  name?: string
  label?: string
  options: SelectOption[]
  value?: string[]
  onChange?: (value: string[]) => void
  onBlur?: () => void
  placeholder?: string
  error?: string
  disabled?: boolean
  className?: string
  multiple: true
}

export type SelectProps = SingleSelectProps | MultiSelectProps

const inputCls = (error?: string, open?: boolean) =>
  cn(
    'h-8 w-full rounded-md border border-[#d9d9d9] bg-white px-3 text-sm text-gray-800 outline-none transition-colors',
    'hover:border-[#4096ff]',
    open && 'border-[#1677ff] shadow-[0_0_0_2px_rgba(5,145,255,0.1)]',
    'disabled:cursor-not-allowed disabled:bg-gray-50 disabled:text-gray-400 disabled:hover:border-[#d9d9d9]',
    error && 'border-red-400 hover:border-red-400',
    open && error && 'border-red-500 shadow-[0_0_0_2px_rgba(255,38,5,0.06)]',
  )

const Select = forwardRef<HTMLDivElement, SelectProps>(
  ({ name, label, options, value, onChange, onBlur, placeholder = 'Select...', error, disabled, className, multiple }, ref) => {
    const id = name

    if (!multiple) {
      return (
        <div ref={ref} className={cn('flex flex-col gap-1', className)}>
          {label && (
            <label htmlFor={id} className="text-sm text-gray-800 font-medium leading-5">
              {label}
            </label>
          )}
          <div className="relative">
            <select
              id={id}
              name={name}
              value={(value as string | undefined) ?? ''}
              disabled={disabled}
              onBlur={onBlur}
              onChange={(e) => (onChange as ((v: string) => void) | undefined)?.(e.target.value)}
              className={cn(
                inputCls(error),
                'cursor-pointer appearance-none pr-8',
                !value && 'text-gray-400',
              )}
            >
              <option value="" disabled hidden>{placeholder}</option>
              {options.map((opt) => (
                <option key={opt.value} value={opt.value} disabled={opt.disabled}>
                  {opt.label}
                </option>
              ))}
            </select>
            <span className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 text-gray-400">
              <svg className="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" />
              </svg>
            </span>
          </div>
          {error && <p className="text-xs text-red-500">{error}</p>}
        </div>
      )
    }

    return (
      <div ref={ref} className={cn('flex flex-col gap-1', className)}>
        {label && <span className="text-sm text-gray-800 font-medium leading-5">{label}</span>}
        <MultiSelectDropdown
          name={name}
          options={options}
          value={(value as string[] | undefined) ?? []}
          onChange={onChange as (v: string[]) => void}
          onBlur={onBlur}
          placeholder={placeholder}
          disabled={disabled}
          error={error}
        />
        {error && <p className="text-xs text-red-500">{error}</p>}
      </div>
    )
  },
)
Select.displayName = 'Select'
export { Select }

// ── MultiSelectDropdown ────────────────────────────────────────────────────────

interface MultiSelectDropdownProps {
  name?: string
  options: SelectOption[]
  value: string[]
  onChange?: (value: string[]) => void
  onBlur?: () => void
  placeholder?: string
  error?: string
  disabled?: boolean
}

function MultiSelectDropdown({ name, options, value, onChange, onBlur, placeholder, error, disabled }: MultiSelectDropdownProps) {
  const [open, setOpen] = useState(false)
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false)
        onBlur?.()
      }
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [onBlur])

  const toggle = (optValue: string) => {
    const next = value.includes(optValue)
      ? value.filter((v) => v !== optValue)
      : [...value, optValue]
    onChange?.(next)
  }

  const selectedLabels = options.filter((o) => value.includes(o.value)).map((o) => o.label)

  return (
    <div ref={containerRef} className="relative">
      <input type="hidden" name={name} value={value.join(',')} />
      <button
        type="button"
        disabled={disabled}
        onClick={() => setOpen((o) => !o)}
        className={cn(inputCls(error, open), 'flex cursor-pointer items-center justify-between')}
      >
        <span className={cn('truncate text-sm', selectedLabels.length === 0 && 'text-gray-400')}>
          {selectedLabels.length > 0 ? selectedLabels.join(', ') : placeholder}
        </span>
        <svg
          className={cn('ml-2 h-3.5 w-3.5 shrink-0 text-gray-400 transition-transform', open && 'rotate-180')}
          fill="currentColor" viewBox="0 0 20 20"
        >
          <path fillRule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" />
        </svg>
      </button>

      {open && (
        <div className="absolute z-20 mt-1 max-h-56 w-full overflow-auto rounded-md border border-[#f0f0f0] bg-white shadow-md">
          {options.length === 0 ? (
            <div className="px-3 py-2 text-sm text-gray-400">No options</div>
          ) : (
            options.map((opt) => (
              <label
                key={opt.value}
                className={cn(
                  'flex cursor-pointer items-center gap-2 px-3 py-2 text-sm text-gray-700 hover:bg-[#f5f5f5]',
                  opt.disabled && 'cursor-not-allowed opacity-50',
                  value.includes(opt.value) && 'bg-blue-50 text-blue-600',
                )}
              >
                <input
                  type="checkbox"
                  checked={value.includes(opt.value)}
                  disabled={opt.disabled}
                  onChange={() => !opt.disabled && toggle(opt.value)}
                  className="h-4 w-4 rounded border-[#d9d9d9] accent-blue-500"
                />
                {opt.label}
              </label>
            ))
          )}
        </div>
      )}
    </div>
  )
}
