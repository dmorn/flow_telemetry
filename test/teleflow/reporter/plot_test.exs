defmodule TeleFlow.Reporter.PlotTest do
  use ExUnit.Case

  alias Support.Roses
  alias TeleFlow.Reporter.Plot
  alias TeleFlow.Collector.FS

  test "encode_span_events/1 produces a VegaLite spec" do
    id = TeleFlow.uniq_event_prefix()
    collector = FS.new(id)

    ["roses are red", "violets are blue"]
    |> Roses.flow_from_enumerable()
    |> TeleFlow.attach(collector, id)
    |> Flow.run()

    %VegaLite{} =
      collector
      |> FS.stream_stop_events()
      |> Enum.into([])
      |> then(&Plot.encode_stop_events(VegaLite.new(), &1))
  end
end
