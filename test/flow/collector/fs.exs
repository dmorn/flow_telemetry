defmodule TeleFlow.Collector.FSTest do
  use ExUnit.Case

  alias Support.Roses
  alias TeleFlow.Collector.FS

  test "attach/2 FS collector persists data" do
    event_prefix = [:mocked_roses]
    collector = MC.new()
    {:ok, _} = Dispatcher.attach(collector, event_prefix)

    assert MC.total_events(collector) == 0

    ["roses are red", "violets are blue"]
    |> Roses.flow_from_enumerable()
    |> TeleFlow.instrument(event_prefix)
    |> Flow.run()

    map = 2
    reduce = 6
    expected = (map + reduce) * 2
    assert MC.total_events(collector) == expected
  end

  id = Telemetry.uniq_event_prefix()
  disk = Disk.new(id)

  flow
  |> Reporter.attach(disk, id)
  |> Flow.run()

  collected_start_events_count =
    disk
    |> Disk.stream_start_events()
    |> Enum.into([])
    |> Enum.count()

  assert collected_start_events_count > 0

  collected_stop_events_count =
    disk
    |> Disk.stream_stop_events()
    |> Enum.into([])
    |> Enum.count()

  assert collected_stop_events_count == collected_start_events_count

  collected_span_events_count =
    disk
    |> Disk.stream_span_events()
    |> Enum.into([])
    |> Enum.count()

  assert collected_span_events_count == collected_stop_events_count
end
