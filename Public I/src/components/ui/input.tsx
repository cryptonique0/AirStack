import * as React from 'react'
import clsx from 'clsx'

export type InputProps = React.InputHTMLAttributes<HTMLInputElement>

export const Input = React.forwardRef<HTMLInputElement, InputProps>(function Input(
  { className, ...props },
  ref
) {
  return (
    <input
      ref={ref}
      className={clsx(
        'w-full rounded-md bg-white/10 border border-white/20 px-3 py-2 outline-none',
        'focus:ring-2 focus:ring-white/30 placeholder:text-white/50',
        'disabled:opacity-50 disabled:cursor-not-allowed',
        className
      )}
      {...props}
    />
  )
})
