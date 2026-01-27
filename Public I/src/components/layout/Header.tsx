import { Link, NavLink } from 'react-router-dom'
import { FlaskConical, Users, Code2, Info } from 'lucide-react'

export function Header() {
  const navClass = ({ isActive }: { isActive: boolean }) =>
    `px-3 py-2 rounded-md text-sm font-medium ${isActive ? 'bg-white/10' : 'hover:bg-white/5'}`

  return (
    <header className="border-b border-white/10 sticky top-0 bg-black/30 backdrop-blur">
      <div className="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
        <Link to="/" className="flex items-center gap-2 font-semibold">
          <FlaskConical className="h-5 w-5" />
          Base-ville
        </Link>
        <nav className="flex items-center gap-2">
          <NavLink to="/work" className={navClass}><Code2 className="inline h-4 w-4 mr-1" />Work</NavLink>
          <NavLink to="/team" className={navClass}><Users className="inline h-4 w-4 mr-1" />Team</NavLink>
          <NavLink to="/open-source" className={navClass}><Code2 className="inline h-4 w-4 mr-1" />Open Source</NavLink>
          <NavLink to="/about" className={navClass}><Info className="inline h-4 w-4 mr-1" />About</NavLink>
        </nav>
      </div>
    </header>
  )
}
