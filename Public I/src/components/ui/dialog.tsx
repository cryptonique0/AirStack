import * as DialogPrimitive from '@radix-ui/react-dialog'
import { X } from 'lucide-react'

export const Dialog = DialogPrimitive.Root
export const DialogTrigger = DialogPrimitive.Trigger
export const DialogPortal = DialogPrimitive.Portal

export function DialogOverlay() {
  return <DialogPrimitive.Overlay className="fixed inset-0 bg-black/60" />
}

export function DialogContent({ title, children }: { title?: string; children: React.ReactNode }) {
  return (
    <DialogPortal>
      <DialogOverlay />
      <DialogPrimitive.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[90vw] max-w-md rounded-lg border border-white/20 bg-black/80 backdrop-blur p-4 shadow-xl">
        <div className="flex items-center justify-between mb-3">
          {title && <h3 className="text-lg font-semibold">{title}</h3>}
          <DialogPrimitive.Close className="rounded-md p-1 hover:bg-white/10" aria-label="Close">
            <X className="h-4 w-4" />
          </DialogPrimitive.Close>
        </div>
        {children}
      </DialogPrimitive.Content>
    </DialogPortal>
  )
}
