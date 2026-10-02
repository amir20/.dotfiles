import { expect, test } from 'claude-code/testing'

import { label } from './label'

test('label', () => {
  expect(label('cd api && go test ./...')).toBe('go test ./...')
  expect(label('cd ui && bun run typecheck && bun run test')).toBe('bun run test')
})
