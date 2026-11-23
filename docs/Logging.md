# Logging

You can set up logging for the library using the `WPNLogger` class.

## Verbosity Level

You can limit the amount of logged information via the `verboseLevel` property.

| Level                  | Description                                       |
| ---------------------- | ------------------------------------------------- |
| `off`                  | Silences all logs.                                |
| `errors`               | Only errors will be logged.                       |
| `warnings` _(default)_ | Errors and warnings will be logged.               |
| `info`                 | Errors, warnings, and info messages will be logged. |
| `debug`                | All messages will be logged.                      |

## Character limit

To prevent huge logs from being printed, the default limit is 12,000 characters per log. You can change this via `WPNLogger.characterLimit`.

## HTTP traffic logs

- You can turn on or off logging of HTTP requests and responses with the `WPNLogger.logHttpTraffic` property.
- You can filter which headers will be logged with the `WPNLogger.httpHeadersToSkip` property.

## Logger Delegate

If you want to process logs on your own (for example, log them to a file or a cloud service), you can set `WPNLogger.delegate`.
