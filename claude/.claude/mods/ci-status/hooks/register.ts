import type { EngineInterface, Register } from 'claude-code'

import { summarize } from './summarize'
import type { Run } from './summarize'

const POLL_MS = 60_000

let sha = ''
let isDone = false
let isBusy = false
let cacheDir = ''
let prBranch = ''
let prCheckedAt = 0

const PR_EVERY_MS = 5 * 60_000

// ~/.claude/statusline.sh shows ~/.cache/claude-ci/<HEAD sha> next to the branch.
async function publish($: EngineInterface, commit: string, line: string) {
  if (!cacheDir) {
    const home = await $.process.run(['printenv', 'HOME'])
    cacheDir = `${home.stdout.trim()}/.cache/claude-ci`
  }
  await $.fs.write(`${cacheDir}/${commit}`, line)
}

// The open PR for a branch, as ~/.cache/claude-ci/pr-<branch with / as ->: its number, or empty.
async function refreshPR($: EngineInterface) {
  const b = await $.process.run(['git', 'symbolic-ref', '--quiet', '--short', 'HEAD'])
  const branch = b.stdout.trim()
  if (b.exitCode !== 0 || !branch) return
  const now = await $.clock.now()
  if (branch === prBranch && now - prCheckedAt < PR_EVERY_MS) return
  prBranch = branch
  prCheckedAt = now
  const pr = await $.process.run(['gh', 'pr', 'view', branch, '--json', 'number,state', '-q', 'select(.state=="OPEN") | .number'])
  await publish($, `pr-${branch.replaceAll('/', '-')}`, pr.exitCode === 0 ? pr.stdout.trim() : '')
}

async function refresh($: EngineInterface) {
  if (isBusy) return
  isBusy = true
  try {
    const head = await $.process.run(['git', 'rev-parse', 'HEAD'])
    if (head.exitCode !== 0) return
    const current = head.stdout.trim()
    await refreshPR($)
    // A finished commit never changes; only ask GitHub again when HEAD moves.
    if (current === sha && isDone) return

    const gh = await $.process.run([
      'gh', 'run', 'list', '--commit', current, '--limit', '30',
      '--json', 'status,conclusion,workflowName',
    ])
    if (gh.exitCode !== 0) {
      await publish($, current, 'error\tgh failed')
      return
    }
    const s = summarize(current, JSON.parse(gh.stdout) as Run[])
    const wasRunning = current === sha && !isDone
    await publish($, current, s.line)
    if (wasRunning && s.isDone) {
      $.ui.toast(s.failed.length > 0 ? `CI failed: ${s.failed.join(', ')}` : 'CI passed', { timeoutMs: 8000 })
    }
    sha = current
    isDone = s.isDone
  } catch {
    // The status line simply shows nothing for this commit.
  } finally {
    isBusy = false
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const r = await next(e)
    // Earlier versions pinned a plugin status line; the shell status line has it now.
    $.ui.status(undefined)
    void refresh($)
    $.clock.every(POLL_MS, () => void refresh($))
    return r
  })

  // A turn may have committed or pushed.
  on('turn.complete', async ($, e, next) => {
    const r = await next(e)
    void refresh($)
    return r
  })
}
