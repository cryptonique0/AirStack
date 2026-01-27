import { useEffect } from 'react'
import AOS from 'aos'
import 'aos/dist/aos.css'
import { Routes, Route } from 'react-router-dom'
import { Header } from './components/layout/Header'
import { Footer } from './components/layout/Footer'
import Home from './pages/Home'
import Work from './pages/Work'
import Team from './pages/Team'
import OpenSource from './pages/OpenSource'
import About from './pages/About'

export default function App() {
  useEffect(() => {
    AOS.init({ once: true, duration: 600, easing: 'ease-out-cubic' })
  }, [])

  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      <main className="flex-1">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/work" element={<Work />} />
          <Route path="/team" element={<Team />} />
          <Route path="/open-source" element={<OpenSource />} />
          <Route path="/about" element={<About />} />
        </Routes>
      </main>
      <Footer />
    </div>
  )
}
