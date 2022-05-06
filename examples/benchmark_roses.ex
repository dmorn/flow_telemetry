alias TeleFlow.Reporter.Report
alias TeleFlow.Collector.FS

require Logger

Logger.info("Generating input")

search_space =
  ?a..?z
  |> Enum.into([])
  |> Enum.concat([?\s, ?\s])
  |> IO.chardata_to_string()
  |> String.graphemes()

generate_input = fn size ->
  Range.new(0, size)
  |> Enum.map(fn _ -> Enum.random(search_space) end)
  |> IO.chardata_to_string()
end

input =
  Range.new(0, 500)
  |> Enum.map(fn _ -> generate_input.(5_000) end)

new_flow = fn input, opts ->
  input
  |> Flow.from_enumerable(opts.init)
  |> Flow.flat_map(&String.split/1)
  |> Flow.partition(opts.partition)
  |> Flow.reduce(fn -> %{} end, fn x, acc ->
    Map.update(acc, x, 1, fn old -> old + 1 end)
  end)
end

bench_flow = fn flow ->
  id = TeleFlow.uniq_event_prefix()
  collector = FS.new(id)

  Logger.info("Executing Flow #{inspect(id)}")

  flow
  |> TeleFlow.attach(collector, id)
  |> Flow.run()

  spans = FS.stream_span_events(collector)

  Logger.info("Generating Report")
  Report.from_spans(spans, :millisecond)
end

reports =
  [
    %{
      init: [stages: 4],
      partition: [stages: 4]
    },
    %{
      init: [stages: 8],
      partition: [stages: 4]
    },
    %{
      init: [stages: 16],
      partition: [stages: 4]
    },
    %{
      init: [stages: 4],
      partition: [stages: 4]
    },
    %{
      init: [stages: 4],
      partition: [stages: 8]
    },
    %{
      init: [stages: 4],
      partition: [stages: 16]
    }
  ]
  |> Enum.map(fn opts -> {opts, new_flow.(input, opts)} end)
  |> Enum.map(fn {opts, flow} ->
    Logger.info("Benchmarking configuration #{inspect(opts)}")
    {opts, bench_flow.(flow)}
  end)

IO.inspect(reports)

keys_of_interest = [
  :average,
  :maximum,
  :minimum,
  :percentiles,
  :sample_size,
  :total,
  :standard_deviation
]

final_report =
  reports
  |> Enum.map(fn {_opts, report} -> Map.get(report.stats, [:global]) end)
  |> Enum.map(fn global -> global.total end)
  |> Statistex.statistics(percentiles: [25, 50, 75])
  |> Map.take(keys_of_interest)

IO.inspect(reports)
IO.inspect(final_report)
