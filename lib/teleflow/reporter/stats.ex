defmodule TeleFlow.Reporter.Report do
  # TODO: Implement IO.inspect protocol?

  alias TeleFlow.Reporter.Report
  alias TeleFlow.Event.Span

  @type t :: %__MODULE__{stats: Keyword.t()}
  defstruct stats: []

  @spec from_spans(Enumerable.t(), Span.time_unit()) :: Report.t()
  def from_spans(stream, resolution \\ :millisecond) do
    stats =
      stream
      |> Stream.map(&Span.convert_time_unit(&1, resolution))
      |> Enum.group_by(fn %Span{id: id} -> id end)
      |> Enum.map(fn {k, spans} ->
        stats =
          spans
          |> Enum.map(fn %Span{duration: duration} -> duration end)
          |> Statistex.statistics(percentiles: [25, 50, 75])

        {k, stats}
      end)

    # TODO: sort by depth?

    %Report{stats: stats}
  end
end
