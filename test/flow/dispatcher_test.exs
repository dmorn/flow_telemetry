defmodule Flow.Telemetry.DispatcherTest do
  use ExUnit.Case
  alias Support.Roses
  alias Support.MockCollector, as: MC
  alias Flow.Telemetry.Dispatcher

  test "attach/2 collects events in MockCollector" do
    event_prefix = [:mocked_roses]
    collector = MC.new()
    {:ok, _} = Dispatcher.attach(collector, event_prefix)

    assert MC.total_events(collector) == 0

    ["roses are red", "violets are blue"]
    |> Roses.flow_from_enumerable()
    |> Flow.Telemetry.instrument(event_prefix)
    |> Flow.run()

    map = 2
    reduce = 6
    expected = (map + reduce) * 2
    assert MC.total_events(collector) == expected
  end
end
