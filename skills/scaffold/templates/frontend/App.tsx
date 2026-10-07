import { useEffect, useState } from 'react'

type Health = { status: string }

export default function App() {
  const [health, setHealth] = useState<Health | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetch('/api/health')
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        return res.json() as Promise<Health>
      })
      .then(setHealth)
      .catch((e: Error) => setError(e.message))
  }, [])

  return (
    <main className="mx-auto max-w-2xl p-8 font-sans">
      <h1 className="text-3xl font-bold text-slate-900">Hackathon App</h1>
      <p className="mt-4 text-slate-700">
        Backend status:{' '}
        {error ? (
          <span className="font-semibold text-red-600">unreachable ({error})</span>
        ) : health ? (
          <span className="font-semibold text-green-700">{health.status}</span>
        ) : (
          <span className="text-slate-500">checking...</span>
        )}
      </p>
    </main>
  )
}
