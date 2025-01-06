# oslo

An `os_log` viewer for iOS that supports streaming both real-time logs and archived logs.

## Features
- View real-time logs
- View archived logs (even if they weren't streamed live)
  - Does not include logs prior to the last reboot
- Unredacts `<private>` values in log messages
- Process name filtering
- Syntax highlighting by [kat](https://github.com/Theldus/kat/tree/master)
- PID-based grouping + last-log filtering
  - "for each recent crash of `<process>`, show the last couple of logs that were printed before it terminated, grouped by PID and ordered by last-event-in-group timestamp" 


## Usage

```
oslo [-l] [-s] [-g] [ProcessName]

Options:
  -l          Live logs (default)
  -s          Stored/archived logs
    -g          Group logs by PID (requires -s)
  ProcessName Filter by process name
```


[![asciicast](https://asciinema.org/a/tet26ugcwutH0CIwjKeS99C1P.svg?poster=npt:07)](https://asciinema.org/a/tet26ugcwutH0CIwjKeS99C1P?poster=npt:07)


Tested on iOS 14.0 - 18.2