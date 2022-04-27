# WIP: Flow.Telemetry
Instrument Flow(s) with Telemetry spans. Depends on flow and uses its internal
:operations and :producers keys to override functions. Pretty much an
experiment for now.

## Usage
This library provides a `Flow.Telemetry.instrument/2` function that
takes a [Flow](https://github.com/dashbitco/flow) and returns its
instrumented version using [Telemetry
Spans](https://github.com/beam-telemetry/telemetry#spans). Users should
then use telemetry facilities to collect and handle the events. Check
`test/flow/telemetry_test.exs` for an example.
