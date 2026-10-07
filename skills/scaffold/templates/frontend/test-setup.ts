import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach } from 'vitest'

// Unmount whatever each test rendered; automatic cleanup only runs when Vitest globals are on.
afterEach(cleanup)
