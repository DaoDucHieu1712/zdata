import { forwardRef } from 'react'
import { cn } from '@/lib/utils/cn'

export interface CheckboxProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'type' | 'onChange'> {
  label?: string
  description?: string
  error?: string
  onChange?: (checked: boolean) => void
}

const Checkbox = forwardRef<HTMLInputElement, CheckboxProps>(
  ({ label, description, error, className, id, name, onChange, ...props }, ref) => {
    const inputId = id ?? name
    return (
      <div className="flex flex-col gap-1">
        <label htmlFor={inputId} className="flex cursor-pointer items-start gap-2">
          <span className="relative mt-0.5 flex h-4 w-4 shrink-0 items-center justify-center">
            <input
              ref={ref}
              type="checkbox"
              id={inputId}
              name={name}
              onChange={(e) => onChange?.(e.target.checked)}
              className={cn(
                'peer h-4 w-4 cursor-pointer appearance-none rounded-sm border border-[#d9d9d9] bg-white transition-colors',
                'hover:border-[#4096ff]',
                'checked:border-[#1677ff] checked:bg-[#1677ff]',
                'focus:outline-none focus:shadow-[0_0_0_2px_rgba(5,145,255,0.1)]',
                'disabled:cursor-not-allowed disabled:opacity-50',
                error && 'border-red-400',
                className,
              )}
              {...props}
            />
            <svg
              className="pointer-events-none absolute hidden h-3 w-3 text-white peer-checked:block"
              fill="none" viewBox="0 0 12 12" stroke="currentColor" strokeWidth={2.5}
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M2 6l3 3 5-5" />
            </svg>
          </span>
          {(label || description) && (
            <span className="flex flex-col">
              {label && <span className="text-sm text-gray-800">{label}</span>}
              {description && <span className="text-xs text-gray-400">{description}</span>}
            </span>
          )}
        </label>
        {error && <p className="text-xs text-red-500">{error}</p>}
      </div>
    )
  },
)
Checkbox.displayName = 'Checkbox'
export { Checkbox }
