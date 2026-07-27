import { forwardRef } from 'react'
import { cn } from '@/lib/utils/cn'

export interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string
  error?: string
  hint?: string
}

const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ label, error, hint, className, id, name, rows = 3, ...props }, ref) => {
    const inputId = id ?? name
    return (
      <div className="flex flex-col gap-1">
        {label && (
          <label htmlFor={inputId} className="text-sm text-gray-800 font-medium leading-5">
            {label}
          </label>
        )}
        <textarea
          ref={ref}
          id={inputId}
          name={name}
          rows={rows}
          className={cn(
            'w-full resize-y rounded-md border border-[#d9d9d9] bg-white px-3 py-1.5 text-sm text-gray-800 outline-none transition-colors placeholder:text-gray-400',
            'hover:border-[#4096ff]',
            'focus:border-[#1677ff] focus:shadow-[0_0_0_2px_rgba(5,145,255,0.1)]',
            'disabled:cursor-not-allowed disabled:bg-gray-50 disabled:text-gray-400 disabled:hover:border-[#d9d9d9]',
            error && 'border-red-400 hover:border-red-400 focus:border-red-500 focus:shadow-[0_0_0_2px_rgba(255,38,5,0.06)]',
            className,
          )}
          {...props}
        />
        {error && <p className="text-xs text-red-500">{error}</p>}
        {hint && !error && <p className="text-xs text-gray-400">{hint}</p>}
      </div>
    )
  },
)
Textarea.displayName = 'Textarea'
export { Textarea }
