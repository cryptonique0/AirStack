/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ['class'],
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: '#1f2937',
          light: '#374151',
          dark: '#0f172a'
        }
      }
    }
  },
  plugins: []
}
