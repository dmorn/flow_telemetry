defmodule TeleFlowTest do
  use ExUnit.Case

  alias Support.Roses
  alias Support.MockCollector, as: MC
  alias TeleFlow.Collector.FS
  alias TeleFlow

  test "instrument/2 produces a valid flow" do
    have =
      ["roses are red", "violets are blue"]
      |> Roses.flow_from_enumerable()
      |> TeleFlow.instrument([:roses])
      |> Enum.into(%{})

    want = %{
      "roses" => 1,
      "are" => 2,
      "red" => 1,
      "violets" => 1,
      "blue" => 1
    }

    assert have == want
  end

  test "attach/2 collects events in MockCollector" do
    collector = MC.new()
    assert MC.total_events(collector) == 0

    ["roses are red", "violets are blue"]
    |> Roses.flow_from_enumerable()
    |> TeleFlow.attach(collector)
    |> Flow.run()

    map = 2
    reduce = 6
    expected = (map + reduce) * 2
    assert MC.total_events(collector) == expected
  end

  test "attach/3 collects events in FS Collector" do
    id = TeleFlow.uniq_event_prefix()
    collector = FS.new(id)

    ["roses are red", "violets are blue"]
    |> Roses.flow_from_enumerable()
    |> TeleFlow.attach(collector, id)
    |> Flow.run()

    collected_start_events_count =
      collector
      |> FS.stream_start_events()
      |> Enum.into([])
      |> Enum.count()

    assert collected_start_events_count > 0

    collected_stop_events_count =
      collector
      |> FS.stream_stop_events()
      |> Enum.into([])
      |> Enum.count()

    assert collected_stop_events_count == collected_start_events_count

    collected_span_events_count =
      collector
      |> FS.stream_span_events()
      |> Enum.into([])
      |> Enum.count()

    assert collected_span_events_count == collected_stop_events_count
  end
end
