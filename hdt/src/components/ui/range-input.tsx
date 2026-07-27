'use client'

import { forwardRef } from 'react'
import { cn } from '@/lib/utils/cn'

export interface RangeInputProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label?: string
  error?: string
  showValue?: boolean
  valueSuffix?: string
}

const RangeInput = forwardRef<HTMLInputElement, RangeInputProps>(
  ({ label, error, showValue = true, valueSuffix = '', className, id, name, min = 0, max = 100, value, ...props }, ref) => {
    const inputId = id ?? name
    return (
      <div className="flex flex-col gap-1.5">
        {(label || showValue) && (
          <div className="flex items-center justify-between">
            {label && (
              <label htmlFor={inputId} className="text-sm text-gray-800 font-medium leading-5">
                {label}
              </label>
            )}
            {showValue && (
              <span className="rounded bg-blue-50 px-1.5 py-0.5 text-xs font-semibold text-blue-600">
                {value ?? min}{valueSuffix}
              </span>
            )}
          </div>
        )}
        <div className="flex items-center gap-2">
          <span className="w-8 text-right text-xs text-gray-400">{min}</span>
          <div className="relative flex-1">
            <input
              ref={ref}
              type="range"
              id={inputId}
              name={name}
              min={min}
              max={max}
              value={value}
              className={cn(
                'h-1.5 w-full cursor-pointer appearance-none rounded-full bg-gray-200 outline-none',
                '[&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:w-4',
                '[&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:rounded-full',
                '[&::-webkit-slider-thumb]:border-2 [&::-webkit-slider-thumb]:border-[#1677ff] [&::-webkit-slider-thumb]:bg-white',
                '[&::-webkit-slider-thumb]:shadow-sm [&::-webkit-slider-thumb]:transition-transform',
                '[&::-webkit-slider-thumb]:hover:scale-125',
                'disabled:cursor-not-allowed disabled:opacity-50',
                error && '[&::-webkit-slider-thumb]:border-red-500',
                className,
              )}
              {...props}
            />
          </div>
          <span className="w-8 text-xs text-gray-400">{max}</span>
        </div>
        {error && <p className="text-xs text-red-500">{error}</p>}
      </div>
    )
  },
)
RangeInput.displayName = 'RangeInput'
export { RangeInput }
