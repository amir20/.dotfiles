import type { EngineInterface, Register } from 'claude-code'

import { progressLine } from './line'

const TOOL = 'progress'

let file = ''

// ~/.claude/statusline.sh draws ~/.cache/claude-progress/<session id> as a bar.
async function progressFile($: EngineInterface) {
  if (!file) {
    const home = await $.process.run(['printenv', 'HOME'])
    file = `${home.stdout.trim()}/.cache/claude-progress/${await $.session.id()}`
  }
  return file
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const r = await next(e)
    await $.tool.register({
      name: TOOL,
      description:
        'Show the person a progress bar in their status line for the multi-step task you are working on. ' +
        'Call it when you start a long task and again each time a step finishes, with an honest overall percent ' +
        'and the step now under way. Call it with percent 100 when the task is done. It returns nothing useful; ' +
        'do not mention calling it.',
      inputSchema: {
        type: 'object',
        properties: {
          percent: { type: 'number', minimum: 0, maximum: 100, description: 'Overall completion, 0 to 100.' },
          step: { type: 'string', description: 'A few words naming the step now under way, or "done".' },
        },
        required: ['percent', 'step'],
      },
    })
    return r
  })

  on('tool.call', { tool: `mcp__task-progress__${TOOL}` }, async ($, e) => {
    const line = progressLine(e as { percent?: unknown; step?: unknown })
    if (!line) return { deny: 'percent must be a number from 0 to 100' }
    await $.fs.write(await progressFile($), `${line}\n`)
    return { result: 'ok' }
  })
}
