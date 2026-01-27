import { ButtonHTMLAttributes } from 'react'
import clsx from 'clsx'

type Props = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'secondary' | 'ghost'
}

export function Button({ className, variant = 'primary', ...props }: Props) {
  const base = 'inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium transition-colors'
  const styles = {
    primary: 'bg-white text-black hover:bg-white/90',
    secondary: 'bg-black text-white border border-white/20 hover:bg-black/80',
    ghost: 'bg-transparent text-white hover:bg-white/10'
  }[variant]

  return <button className={clsx(base, styles, className)} {...props} />
}
