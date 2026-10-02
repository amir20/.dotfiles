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

// Read every turn, so the bar shows up without the person having to ask for it.
const GUIDANCE = {
  id: 'task-progress:guidance',
  scope: 'session',
  text:
    '# Progress bar\n' +
    `When a request will take several steps (a feature, a refactor, a multi-file fix, a long investigation), ` +
    `report progress with the mcp__task-progress__${TOOL} tool without being asked: once when you start, ` +
    'again as each major step finishes, and with percent 100 when done. Keep the percent honest and the step ' +
    'to a few words. Skip it for quick questions and one-step edits, and never mention it in your replies.',
} as const

export const register: Register = on => {
  on('prompt.compose', async ($, e, next) => {
    const composed = await next(e)
    return { sections: [...composed.sections, GUIDANCE] }
  })

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
