import { expect, test } from 'claude-code/testing'

import { summarize } from './summarize'

const sha = '1cb6244cabcdef'

test('all green', () => {
  const s = summarize(sha, [
    { status: 'completed', conclusion: 'success', workflowName: 'Go CI' },
    { status: 'completed', conclusion: 'success', workflowName: 'Docker' },
  ])
  expect(s.text).toBe('CI 1cb6244 ✓ 2 passed')
  expect(s.isDone).toBe(true)
})

test('a rerun replaces its older failure', () => {
  const s = summarize(sha, [
    { status: 'completed', conclusion: 'success', workflowName: 'Go CI' },
    { status: 'completed', conclusion: 'failure', workflowName: 'Go CI' },
  ])
  expect(s.text).toBe('CI 1cb6244 ✓ 1 passed')
})

test('running and failed', () => {
  const s = summarize(sha, [
    { status: 'in_progress', conclusion: '', workflowName: 'Docker' },
    { status: 'completed', conclusion: 'failure', workflowName: 'UI CI' },
  ])
  expect(s.text).toBe('CI 1cb6244 ✗ UI CI, 1 running')
  expect(s.isDone).toBe(false)
})
