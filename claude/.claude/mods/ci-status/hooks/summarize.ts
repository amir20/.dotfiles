export type Run = { status: string; conclusion: string; workflowName: string }

const BAD = new Set(['failure', 'timed_out', 'startup_failure', 'action_required'])

// gh lists newest first; a rerun shares its workflow's name, so the first one wins.
export function latestPerWorkflow(runs: readonly Run[]): Run[] {
  const seen = new Map<string, Run>()
  for (const r of runs) {
    if (!seen.has(r.workflowName)) seen.set(r.workflowName, r)
  }
  return [...seen.values()]
}

// `line` is what ~/.claude/statusline.sh reads: state<TAB>detail.
export type Summary = { text: string; line: string; isDone: boolean; failed: string[] }

export function summarize(sha: string, all: readonly Run[]): Summary {
  const runs = latestPerWorkflow(all)
  const head = `CI ${sha.slice(0, 7)}`
  if (runs.length === 0) {
    return { text: `${head}: no runs`, line: 'none\t', isDone: true, failed: [] }
  }
  const failed = runs.filter(r => r.status === 'completed' && BAD.has(r.conclusion)).map(r => r.workflowName)
  const pending = runs.filter(r => r.status !== 'completed')
  if (failed.length > 0) {
    const more = pending.length > 0 ? `, ${pending.length} running` : ''
    return { text: `${head} ✗ ${failed.join(', ')}${more}`, line: `fail\t${failed.join(', ')}${more}`, isDone: pending.length === 0, failed }
  }
  if (pending.length > 0) {
    return { text: `${head} ⏳ ${runs.length - pending.length}/${runs.length} done`, line: `run\t${runs.length - pending.length}/${runs.length}`, isDone: false, failed }
  }
  return { text: `${head} ✓ ${runs.length} passed`, line: `pass\t${runs.length}`, isDone: true, failed }
}
