import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { Button } from '../ui/button'
import { Input } from '../ui/input'

const schema = z.object({
  email: z.string().email('Please enter a valid email')
})

type FormData = z.infer<typeof schema>

export function NewsletterForm() {
  const { register, handleSubmit, formState: { errors, isSubmitting, isSubmitSuccessful } } = useForm<FormData>({
    resolver: zodResolver(schema)
  })

  const onSubmit = async (data: FormData) => {
    await new Promise(r => setTimeout(r, 500))
    alert(`Subscribed: ${data.email}`)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="max-w-md space-y-3">
      <div>
        <label className="block text-sm mb-1">Email</label>
        <Input type="email" placeholder="you@example.com" {...register('email')} />
        {errors.email && <p className="text-red-400 text-sm mt-1">{errors.email.message}</p>}
      </div>
      <Button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Submitting...' : 'Subscribe'}
      </Button>
      {isSubmitSuccessful && <p className="text-green-400 text-sm">Thanks for subscribing!</p>}
    </form>
  )
}
