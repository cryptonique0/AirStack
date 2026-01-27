import * as TabsPrimitive from '@radix-ui/react-tabs'
import clsx from 'clsx'

export const Tabs = TabsPrimitive.Root
export const TabsList = ({ className, ...props }: TabsPrimitive.TabsListProps) => (
  <TabsPrimitive.List
    className={clsx('inline-flex rounded-md border border-white/20 bg-black/50 p-1', className)}
    {...props}
  />
)
export const TabsTrigger = ({ className, ...props }: TabsPrimitive.TabsTriggerProps) => (
  <TabsPrimitive.Trigger
    className={clsx(
      'px-3 py-1.5 text-sm rounded-md',
      'data-[state=active]:bg-white data-[state=active]:text-black',
      'data-[state=inactive]:text-white hover:bg-white/10',
      className
    )}
    {...props}
  />
)
export const TabsContent = ({ className, ...props }: TabsPrimitive.TabsContentProps) => (
  <TabsPrimitive.Content className={clsx('mt-3', className)} {...props} />
)
