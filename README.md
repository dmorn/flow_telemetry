# WIP: TeleFlow
Instrument Flow(s) with Telemetry spans. Depends on flow and uses its internal
:operations and :producers keys to override functions. Pretty much an
experiment for now.

## Usage
This library provides a `TeleFlow.attach/2` function that
takes a [Flow](https://github.com/dashbitco/flow), a Telemetry collector and returns an
instrumented flow that emits [Telemetry
Spans](https://github.com/beam-telemetry/telemetry#spans) when executed.
