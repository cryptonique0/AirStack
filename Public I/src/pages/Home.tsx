import { motion } from 'framer-motion'
import { NewsletterForm } from '../components/forms/NewsletterForm'
import { Dialog, DialogTrigger, DialogContent } from '../components/ui/dialog'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '../components/ui/tabs'
import { Button } from '../components/ui/button'

export default function Home() {
  return (
    <section className="max-w-6xl mx-auto px-4 py-12 space-y-8">
      <motion.h1
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="text-3xl md:text-5xl font-bold"
        data-aos="fade-up"
      >
        Building Tomorrow’s Software Today
      </motion.h1>
      <p className="text-white/80 max-w-2xl" data-aos="fade-up" data-aos-delay="100">
        Base-ville is a modern web platform showcasing innovative projects in AI, blockchain, decentralized infrastructure, and next‑gen technology protocols.
      </p>
      <div data-aos="fade-up" data-aos-delay="200">
        <NewsletterForm />
      </div>
      <div className="grid md:grid-cols-2 gap-6" data-aos="fade-up" data-aos-delay="250">
        <div className="space-y-3">
          <h3 className="text-xl font-semibold">Dialog Demo</h3>
          <Dialog>
            <DialogTrigger asChild>
              <Button>Open Dialog</Button>
            </DialogTrigger>
            <DialogContent title="Hello from Base-ville">
              <p className="text-white/80">This is a shadcn-style dialog using Radix primitives.</p>
            </DialogContent>
          </Dialog>
        </div>

        <div className="space-y-3">
          <h3 className="text-xl font-semibold">Tabs Demo</h3>
          <Tabs defaultValue="one">
            <TabsList>
              <TabsTrigger value="one">One</TabsTrigger>
              <TabsTrigger value="two">Two</TabsTrigger>
            </TabsList>
            <TabsContent value="one">
              <p className="text-white/80">Tab One content showcasing our experiments.</p>
            </TabsContent>
            <TabsContent value="two">
              <p className="text-white/80">Tab Two content focusing on open-source initiatives.</p>
            </TabsContent>
          </Tabs>
        </div>
      </div>
    </section>
  )
}
