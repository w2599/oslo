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

oslo [process] [filters] [options]

#### **Process Selection:**
- `<name>` — Process name (case insensitive substring match)
- `<pid>` — Process ID  
  _(Shows all processes if omitted)_

#### **Filters:**

- `-L, --level <level>` — Log level (`notice`, `debug`, `info`, `error`, `fault`)
- `-a, --after <time>` — Show logs after given time  
  _(Formats: `-1h`, `-30m`, `-1d`, `-1w`, `HH:mm:ss`, `YYYY-MM-DD`, `YYYY-MM-DD HH:mm:ss`)_
- `-b, --before <time>` — Show logs before given time _(same formats as `--after`)_
- `-c, --contains <text>` — Only include messages containing text _(case-insensitive)_
- `-e, --exclude <text>` — Exclude messages containing text _(case-insensitive)_

#### **Options:**
- `-l, --live` — Live logs _(default)_
- `-s, --stored` — Stored logs
- `-g, --group` — Group by process _(only for stored logs)_
- `-j, --json` — JSON output _(not available in live mode)_
- `-f, --file <path>` — Write output to a file
- `-r, --repeats` — Don't drop repeated messages _(default: drop repeats)_
- `-N, --no-color` — Disable color output
- `-h, --help` — Show usage information


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
oslo springboard -s -c "*Exception" -e "simulated_crash"

# Export filtered logs to file
oslo springboard --level=error --file=errors.log

# View all stored logs from the last 24 hours and export to JSON
oslo --stored --after=-1d --json > logs.json

# Show all logs containing "network error" but exclude those with "timeout"
oslo --contains "network error" --exclude "timeout"

# Follow live logs from a PID and write to a file
oslo 12345 --file=logs.txt
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