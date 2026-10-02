// The file ~/.claude/statusline.sh reads: `<percent>\t<step>`, one line.
export function progressLine(input: { percent?: unknown; step?: unknown }): string | undefined {
  const percent = Number(input.percent)
  if (!Number.isFinite(percent)) return undefined
  const clamped = Math.round(Math.min(100, Math.max(0, percent)))
  const step = typeof input.step === 'string' ? input.step.replace(/[\t\r\n]+/g, ' ').trim().slice(0, 80) : ''
  return `${clamped}\t${step}`
}
