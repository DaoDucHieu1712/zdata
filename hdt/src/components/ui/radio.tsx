import { forwardRef } from 'react'
import { cn } from '@/lib/utils/cn'

export interface RadioOption {
  label: string
  value: string
  disabled?: boolean
}

export interface RadioGroupProps {
  name?: string
  label?: string
  options: RadioOption[]
  value?: string
  onChange?: (value: string) => void
  onBlur?: () => void
  error?: string
  direction?: 'horizontal' | 'vertical'
  disabled?: boolean
  className?: string
}

const RadioGroup = forwardRef<HTMLDivElement, RadioGroupProps>(
  ({ name, label, options, value, onChange, onBlur, error, direction = 'vertical', disabled, className }, ref) => {
    return (
      <div ref={ref} className={cn('flex flex-col gap-1', className)}>
        {label && <span className="text-sm text-gray-800 font-medium leading-5">{label}</span>}
        <div className={cn('flex gap-4', direction === 'vertical' ? 'flex-col gap-2' : 'flex-row flex-wrap')}>
          {options.map((opt) => {
            const isChecked = value === opt.value
            const isDisabled = disabled || opt.disabled
            return (
              <label
                key={opt.value}
                className={cn(
                  'flex cursor-pointer items-center gap-2',
                  isDisabled && 'cursor-not-allowed opacity-50',
                )}
              >
                <span className="relative flex h-4 w-4 shrink-0 items-center justify-center">
                  <input
                    type="radio"
                    name={name}
                    value={opt.value}
                    checked={isChecked}
                    disabled={isDisabled}
                    onChange={() => onChange?.(opt.value)}
                    onBlur={onBlur}
                    className={cn(
                      'peer h-4 w-4 cursor-pointer appearance-none rounded-full border border-[#d9d9d9] bg-white transition-colors',
                      'hover:border-[#4096ff]',
                      'checked:border-[#1677ff]',
                      'focus:outline-none focus:shadow-[0_0_0_2px_rgba(5,145,255,0.1)]',
                      'disabled:cursor-not-allowed',
                      error && 'border-red-400',
                    )}
                  />
                  {/* inner dot */}
                  <span className={cn(
                    'pointer-events-none absolute h-2 w-2 rounded-full bg-[#1677ff] transition-transform scale-0',
                    isChecked && 'scale-100',
                  )} />
                </span>
                <span className="text-sm text-gray-700">{opt.label}</span>
              </label>
            )
          })}
        </div>
        {error && <p className="text-xs text-red-500">{error}</p>}
      </div>
    )
  },
)
RadioGroup.displayName = 'RadioGroup'
export { RadioGroup }
