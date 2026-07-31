# process

List/report processes, with a focus on finding (and optionally reaping) zombie/defunct processes.

## Purpose

Quickly filter the process table by user/name, or find zombie processes accumulating on a host and nudge their parents to reap them.

## Requirements

- `ps` supporting GNU-style `-eo <fields>` (standard on Linux)

## Usage

```bash
./process.sh [options]
```

| Option | Description |
|---|---|
| `--zombie` | Only list zombie/defunct processes |
| `--fix` | Attempt to reap zombies found (requires `--zombie`) |
| `-y`, `--yes` | Skip the confirmation prompt before `--fix` acts |
| `--user NAME` | Only show processes owned by this user |
| `--name PATTERN` | Only show processes whose command matches this pattern |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

A table of PID/PPID/%CPU/%MEM/USER/COMMAND (or PID/PPID/USER/COMMAND for `--zombie`), followed by a count.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `'ps -eo ...' is not supported on this system` | Non-GNU `ps` (e.g. BSD, or Windows/MSYS `ps`) | Run on a Linux host with GNU coreutils/procps |
| Zombie still present after `--fix` | Parent process is ignoring `SIGCHLD` | The zombie clears when the parent exits; consider restarting the parent |

## References

- [`ps(1)`](https://man7.org/linux/man-pages/man1/ps.1.html)
- [Zombie process](https://en.wikipedia.org/wiki/Zombie_process)
