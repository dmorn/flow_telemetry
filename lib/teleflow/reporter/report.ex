defmodule TeleFlow.Reporter.Report do
  # TODO: Implement IO.inspect protocol?

  alias TeleFlow.Reporter.Report
  alias TeleFlow.Event.Span

  @type t :: %__MODULE__{stats: Keyword.t()}
  defstruct stats: []

  @spec from_spans(Enumerable.t(), Span.time_unit()) :: Report.t()
  def from_spans(stream, resolution \\ :native) do
    keys_of_interest = [
      :average,
      :maximum,
      :minimum,
      :percentiles,
      :sample_size,
      :total,
      :standard_deviation
    ]

    stats =
      stream
      |> Stream.map(&Span.convert_time_unit(&1, resolution))
      |> Enum.group_by(fn %Span{id: id} -> id end)
      |> Enum.map(fn {k, spans} ->
        stats =
          spans
          |> Enum.map(fn %Span{duration: duration} -> duration end)
          |> Statistex.statistics(percentiles: [25, 50, 75])
          |> Map.take(keys_of_interest)

        {k, stats}
      end)
      |> Enum.into(%{})

    global =
      stats
      |> Enum.map(fn {_k, v} -> v end)
      |> Enum.map(&Map.take(&1, [:total, :sample_size]))
      |> Enum.reduce(fn x, acc ->
        Map.merge(acc, x, fn _, v1, v2 -> v1 + v2 end)
      end)

    stats = Map.put(stats, [:global], global)

    # TODO: sort by depth?

    %Report{stats: stats}
  end
end
