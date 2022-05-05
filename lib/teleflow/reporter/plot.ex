defmodule TeleFlow.Reporter.Plot do
  @moduledoc """
  VegaLite reporter!
  """

  alias VegaLite, as: Vl
  alias TeleFlow.Event.Stop

  @doc """
  Encodes a list of spans into the provided VegaLite specification as data
  source. Processed items count get the y axis, time on x, the color dimension
  is provided by the span identifier. Time is relative to the first span in the
  list.
  """
  @spec encode_stop_events(VegaLite.t(), Enumerable.t()) :: VegaLite.t()
  def encode_stop_events(vl, spans) do
    spans
    |> Enum.sort(fn %{monotonic_time: lhs}, %{monotonic_time: rhs} -> lhs < rhs end)
    |> Stream.transform(%{}, fn %Stop{monotonic_time: t, result_count: count, id: id}, acc ->
      acc = Map.put_new(acc, :_t0, t)
      t0 = Map.get(acc, :_t0)

      {count, acc} =
        Map.get_and_update(acc, id, fn old ->
          old = if old == nil, do: 0, else: old
          new = old + count
          {new, new}
        end)

      {[%{"time" => t - t0, "count" => count, "operation" => id}], acc}
    end)
    |> Enum.into([])
    |> then(&encode_measurements(vl, &1))
  end

  defp encode_measurements(vl, measurements) do
    vl
    |> Vl.data_from_values(measurements)
    |> Vl.encode_field(:x, "time", type: :quantitative, title: "Time (native)")
    |> Vl.encode_field(:y, "count", type: :quantitative, title: "Processed Items")
    |> Vl.encode_field(:color, "operation", type: :nominal, title: "Operation")
  end
end
