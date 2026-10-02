import type { Register } from 'claude-code'

import { label } from './label'

const LONG_MS = 45_000

export const register: Register = on => {
  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    const started = await $.clock.now()
    const ran = await next(e)
    const ms = (await $.clock.now()) - started
    if (ms >= LONG_MS && ran.deny === undefined) {
      const mark = ran.isError ? '✗' : '✓'
      $.ui.toast(`${mark} ${label(e.command)} — ${Math.round(ms / 1000)}s`, { timeoutMs: 10_000 })
    }
    return ran
  })
}
