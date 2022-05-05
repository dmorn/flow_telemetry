alias TeleFlow.Reporter.Report
alias TeleFlow.Collector.FS

require Logger

Logger.info("Generating input")

search_space =
  ?a..?z
  |> Enum.into([])
  |> Enum.concat([?\s, ?\s])
  |> IO.chardata_to_string
  |> String.graphemes()

generate_input = fn size ->
  Range.new(0, size)
  |> Enum.map(fn _ -> Enum.random(search_space) end)
  |> IO.chardata_to_string
end

input =
  Range.new(0, 1_000)
  |> Enum.map(fn _ -> generate_input.(10_000) end)

flow =
  input
  |> Flow.from_enumerable()
  |> Flow.flat_map(&String.split/1)
  |> Flow.partition()
  |> Flow.reduce(fn -> %{} end, fn x, acc ->
    Map.update(acc, x, 1, fn old -> old + 1 end)
  end)

id = TeleFlow.uniq_event_prefix()
collector = FS.new(id)

Logger.info("Executing Flow")

flow
|> TeleFlow.attach(collector, id)
|> Flow.run()

spans = FS.stream_span_events(collector)

Logger.info("Generating Report")

IO.inspect(Report.from_spans(spans))
