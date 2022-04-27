defmodule Support.Roses do
  def flow_from_enumerable(enumerable) do
    enumerable
    |> Flow.from_enumerable()
    |> Flow.flat_map(&String.split/1)
    # For a deterministic partitioning
    |> Flow.partition(stages: 1)
    |> Flow.reduce(fn -> %{} end, fn x, acc ->
      Map.update(acc, x, 1, fn old -> old + 1 end)
    end)
  end
end
