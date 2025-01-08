# oslo

An `os_log` viewer for iOS that supports streaming both real-time logs and archived logs.

- View real-time logs
- View archived logs even if they weren't streamed live (starting from the last reboot)
- Unredacts `<private>` values in log messages
- Process name filtering
- Syntax highlighting
- PID-based grouping + last-log filtering

### Usage

```
oslo [-l] [-s] [-g] [ProcessName]

Options:
  -l          Live logs (default)
  -s          Stored/archived logs
  -g          Group logs by PID (requires -s)
  ProcessName Filter by process name
```

#### Usage Examples

```
# Stream live logs from all processes
oslo -l

# View stored logs for SpringBoard
oslo -s SpringBoard

# View stored logs for TargetApp, grouped by PID and reduced to the last few logs before each termination
oslo -s -g TargetApp
```

### Requirements

* Jailbroken iOS 14.0 or later
  * Earlier versions may work. iOS 14.0 - 18.2 tested
  * Rootless or rootful
* Pre-compiled releases include armv7, armv7s, and arm64 slices

### Screenshots

#### Live log streaming
![oslo](./other/screenshot-allprocs-live.png)


#### Stored logs grouped by PID (and reduced to the last few logs before each crash)
![oslo](./other/screenshot-group-termination-logs-by-PID.png)


#### Demo
[![asciicast](https://asciinema.org/a/tet26ugcwutH0CIwjKeS99C1P.svg?poster=npt:07)](https://asciinema.org/a/tet26ugcwutH0CIwjKeS99C1P?poster=npt:07)



## Credits

* [Theldus](https://github.com/Theldus) for the [kat syntax highlighting](https://github.com/Theldus/kat/tree/master) library