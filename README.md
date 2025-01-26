# oslo

An `os_log` viewer for iOS and macOS that supports streaming both real-time logs and archived logs.

- Real-time and archived log viewing
- Unredacts `<private>` values in log messages
- Advanced filtering by process name, PID, and content with inclusion/exclusion rules
- Time-based filtering
- Syntax highlighting
- Process grouping
- JSON output support

### Usage

```
oslo [process] [filters] [options]

Process:
  <name>         Process name (case insensitive substring match))
  <pid>          Process ID
                 (shows all processes if omitted)

Filters:
  -L, --level    Log level (debug|info|warn|error)
  -a, --after    Time format options:
                   Offset: -1h, -30m, -1d, -1w
                   Date: 2025-01-23
                   Time: 12:34:56
                   Both: 2025-01-23 12:34:56
  -b, --before   Same time formats as --after
  -c, --contains Include messages containing text (case insensitive)
  -e, --exclude  Exclude messages containing text (case insensitive)

Options:
  -l, --live     Live logs (default)
  -s, --stored   Stored logs
  -g, --group    Group by process
  -j, --json     JSON output
  -f, --file     Write to file
  -r, --repeats  Drop repeated messages (default: show all)
  -N, --no-color  Disable color output
```

#### Usage Examples

```bash
# View live SpringBoard logs
oslo springboard|SpringBoard|spr*N*

# View error logs from Notes app in the last 5 minutes
oslo notes --level error --after=-5m
# Error logs up to, but not after, 1 hour ago
oslo notes --level error --before=-1h
# Last 7d, and include all logs that contain 'error'
oslo notes --after=-7d --contains "error"

# Find details about crashes that occurred while logs were not being monitored.
# Case insensitive, wildcard supported
oslo springboard --stored --contains "caught exception" --exclude "ReportCrash"
oslo springboard -s -c "*exception* -e "*crash"

# Export filtered logs to file
oslo springboard --level=error --file=errors.log

# Get JSON output
oslo notes --json > notes_logs.json
```

### Requirements

* macOS 11.5 or later
* Jailbroken iOS 14.0 or later
  * Earlier versions may work. iOS 14.0 - 18.2 tested
  * Rootless or rootful
* Pre-compiled releases for iOS include armv7, armv7s, and arm64 slices

### Screenshots

#### Live log streaming
![oslo](./other/screenshot-allprocs-live.png)

#### Stored logs grouped by PID
![oslo](./other/screenshot-group-termination-logs-by-PID.png)


## Credits

* [Theldus](https://github.com/Theldus) for the [kat syntax highlighting](https://github.com/Theldus/kat/tree/master) library