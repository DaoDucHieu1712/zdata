'use client'

import type { DefaultValues, FieldValues, Path, ControllerRenderProps, SubmitHandler } from 'react-hook-form'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import type { ReactElement, ReactNode } from 'react'
import { cn } from '@/lib/utils/cn'
import { Input } from '@/components/ui/input'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { DatetimeInput } from '@/components/ui/datetime-input'
import { RadioGroup } from '@/components/ui/radio'
import { Checkbox } from '@/components/ui/checkbox'
import { RangeInput } from '@/components/ui/range-input'
import type { SelectOption } from '@/components/ui/select'
import type { RadioOption } from '@/components/ui/radio'

// ── Field config types ─────────────────────────────────────────────────────────

interface BaseField {
  name: string
  label: string
  placeholder?: string
  colSpan?: 1 | 2 | 3 | 4
  disabled?: boolean
}

export type SearchFieldConfig =
  | (BaseField & { type: 'text' | 'number' | 'email' | 'password' })
  | (BaseField & { type: 'textarea'; rows?: number })
  | (BaseField & { type: 'select'; options: SelectOption[]; multiple?: boolean })
  | (BaseField & { type: 'radio'; options: RadioOption[]; direction?: 'horizontal' | 'vertical' })
  | (BaseField & { type: 'checkbox' })
  | (BaseField & { type: 'date' | 'datetime' })
  | (BaseField & { type: 'range'; min?: number; max?: number; step?: number; valueSuffix?: string })

// ── Props ──────────────────────────────────────────────────────────────────────

export interface SearchPanelProps<T extends FieldValues> {
  fields: SearchFieldConfig[]
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  schema: any
  defaultValues?: DefaultValues<T>
  cols?: 2 | 3 | 4
  loading?: boolean
  className?: string
  title?: string
  onSearch: (values: T) => void
  onReset?: () => void
  onChange?: (values: Partial<T>) => void
}

// ── Grid helpers ───────────────────────────────────────────────────────────────

const GRID_COLS: Record<number, string> = {
  2: 'grid-cols-1 sm:grid-cols-2',
  3: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3',
  4: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4',
}

const COL_SPAN: Record<number, string> = {
  1: 'col-span-1',
  2: 'col-span-2',
  3: 'col-span-3',
  4: 'col-span-4',
}

// ── Component ──────────────────────────────────────────────────────────────────

export function SearchPanel<T extends FieldValues>({
  fields,
  schema,
  defaultValues,
  cols = 3,
  loading = false,
  className,
  title = 'Search & Filter',
  onSearch,
  onReset,
}: SearchPanelProps<T>) {
  const { control, handleSubmit, reset } = useForm<T>({
    resolver: zodResolver(schema),
    defaultValues,
  })

  const handleReset = () => {
    reset(defaultValues)
    onReset?.()
  }

  return (
    <div className={cn('rounded-lg border border-[#f0f0f0] bg-white overflow-hidden', className)}>
      {/* Header */}
      <div className="flex items-center gap-2 border-b border-[#f0f0f0] bg-[#fafafa] px-4 py-3">
        <svg className="h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2a1 1 0 01-.293.707L13 13.414V19a1 1 0 01-.553.894l-4 2A1 1 0 017 21v-7.586L3.293 6.707A1 1 0 013 6V4z" />
        </svg>
        <span className="text-sm font-semibold text-gray-700">{title}</span>
      </div>

      {/* Form body */}
      <form onSubmit={handleSubmit(onSearch as SubmitHandler<FieldValues>)} className="px-4 pb-4 pt-4">
        <div className={cn('grid gap-x-4 gap-y-3', GRID_COLS[cols])}>
          {fields.map((fieldConfig) => (
            <div
              key={fieldConfig.name}
              className={cn(fieldConfig.colSpan && COL_SPAN[fieldConfig.colSpan])}
            >
              <Controller
                name={fieldConfig.name as Path<T>}
                control={control}
                render={({ field, fieldState }) =>
                  renderField(
                    fieldConfig,
                    field as ControllerRenderProps<FieldValues, string>,
                    fieldState.error?.message,
                  ) as ReactElement
                }
              />
            </div>
          ))}
        </div>

        {/* Action row */}
        <div className="mt-4 flex items-center justify-end gap-2 border-t border-[#f0f0f0] pt-3">
          <button
            type="button"
            onClick={handleReset}
            disabled={loading}
            className="inline-flex h-8 items-center gap-1.5 rounded border border-gray-300 bg-white px-3 text-sm text-gray-600 transition hover:border-blue-400 hover:text-blue-500 disabled:cursor-not-allowed disabled:opacity-50"
          >
            <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            Reset
          </button>
          <button
            type="submit"
            disabled={loading}
            className="inline-flex h-8 items-center gap-1.5 rounded bg-blue-500 px-4 text-sm font-medium text-white transition hover:bg-blue-600 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {loading ? (
              <svg className="h-3.5 w-3.5 animate-spin" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
              </svg>
            ) : (
              <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-4.35-4.35M17 11A6 6 0 115 11a6 6 0 0112 0z" />
              </svg>
            )}
            {loading ? 'Searching…' : 'Search'}
          </button>
        </div>
      </form>
    </div>
  )
}

// ── Field renderer (unchanged) ─────────────────────────────────────────────────

function renderField(
  config: SearchFieldConfig,
  field: ControllerRenderProps<FieldValues, string>,
  error?: string,
): ReactNode {
  const base = { name: field.name, onBlur: field.onBlur, error, disabled: config.disabled }

  switch (config.type) {
    case 'text':
    case 'number':
    case 'email':
    case 'password':
      return (
        <Input
          {...base}
          ref={field.ref}
          type={config.type}
          label={config.label}
          placeholder={config.placeholder}
          value={(field.value as string | undefined) ?? ''}
          onChange={field.onChange}
        />
      )

    case 'textarea':
      return (
        <Textarea
          {...base}
          ref={field.ref}
          label={config.label}
          placeholder={config.placeholder}
          rows={config.rows}
          value={(field.value as string | undefined) ?? ''}
          onChange={field.onChange}
        />
      )

    case 'select':
      if (config.multiple) {
        return (
          <Select
            {...base}
            label={config.label}
            options={config.options}
            multiple
            value={(field.value as string[] | undefined) ?? []}
            onChange={(v) => field.onChange(v)}
            placeholder={config.placeholder}
          />
        )
      }
      return (
        <Select
          {...base}
          label={config.label}
          options={config.options}
          value={(field.value as string | undefined) ?? ''}
          onChange={(v) => field.onChange(v)}
          placeholder={config.placeholder}
        />
      )

    case 'radio':
      return (
        <RadioGroup
          {...base}
          label={config.label}
          options={config.options}
          direction={config.direction}
          value={(field.value as string | undefined) ?? ''}
          onChange={(v) => field.onChange(v)}
        />
      )

    case 'checkbox':
      return (
        <Checkbox
          {...base}
          ref={field.ref}
          label={config.label}
          checked={Boolean(field.value)}
          onChange={(checked) => field.onChange(checked)}
        />
      )

    case 'date':
      return (
        <DatetimeInput
          {...base}
          ref={field.ref}
          type="date"
          label={config.label}
          value={(field.value as string | undefined) ?? ''}
          onChange={(e) => field.onChange(e.target.value)}
        />
      )

    case 'datetime':
      return (
        <DatetimeInput
          {...base}
          ref={field.ref}
          type="datetime-local"
          label={config.label}
          value={(field.value as string | undefined) ?? ''}
          onChange={(e) => field.onChange(e.target.value)}
        />
      )

    case 'range':
      return (
        <RangeInput
          {...base}
          ref={field.ref}
          label={config.label}
          min={config.min}
          max={config.max}
          step={config.step}
          valueSuffix={config.valueSuffix}
          value={(field.value as number | undefined) ?? config.min ?? 0}
          onChange={field.onChange}
        />
      )
  }
}
