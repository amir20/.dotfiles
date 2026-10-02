import { expect, test } from 'claude-code/testing'

import { progressLine } from './line'

test('writes percent and step', () => {
  expect(progressLine({ percent: 35, step: 'histogram endpoint' })).toBe('35\thistogram endpoint')
})

test('clamps and rounds the percent', () => {
  expect(progressLine({ percent: 140, step: 'x' })).toBe('100\tx')
  expect(progressLine({ percent: -3, step: 'x' })).toBe('0\tx')
  expect(progressLine({ percent: 33.6, step: 'x' })).toBe('34\tx')
})

test('keeps the line to one row', () => {
  expect(progressLine({ percent: 10, step: 'a\tb\nc' })).toBe('10\ta b c')
})

test('refuses a percent that is not a number', () => {
  expect(progressLine({ percent: 'lots', step: 'x' })).toBeUndefined()
})
