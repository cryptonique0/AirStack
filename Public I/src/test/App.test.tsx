import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import App from '../App'

test('renders site header', () => {
  render(<MemoryRouter><App /></MemoryRouter>)
  const links = screen.getAllByText(/Base-ville/i)
  expect(links.length).toBeGreaterThan(0)
})

test('renders navigation links', () => {
  render(<MemoryRouter><App /></MemoryRouter>)
  expect(screen.getByText('Work')).toBeInTheDocument()
  expect(screen.getByText('Team')).toBeInTheDocument()
})
