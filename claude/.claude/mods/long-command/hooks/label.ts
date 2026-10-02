/** A short name for a command: the part after the last `cd … &&`, cut to 40 chars. */
export function label(command: string): string {
  const parts = command.split(/&&|;/).map(s => s.trim()).filter(s => s && !s.startsWith('cd '))
  const last = (parts[parts.length - 1] ?? command).split('\n')[0]
  return last.length > 40 ? `${last.slice(0, 39)}…` : last
}
