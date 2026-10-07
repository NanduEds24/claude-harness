import { render, screen } from '@testing-library/react'
import { afterEach, expect, test, vi } from 'vitest'
import App from './App'

afterEach(() => vi.unstubAllGlobals())

test('shows the backend status from /api/health', async () => {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockResolvedValue({ ok: true, json: () => Promise.resolve({ status: 'OK' }) }),
  )

  render(<App />)

  expect(await screen.findByText('OK')).toBeInTheDocument()
})
