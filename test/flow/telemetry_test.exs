defmodule Flow.TelemetryTest do
  use ExUnit.Case

  defp roses_flow(enumerable) do
    enumerable
    |> Flow.from_enumerable()
    |> Flow.flat_map(&String.split/1)
    # For a deterministic partitioning
    |> Flow.partition(stages: 1)
    |> Flow.reduce(fn -> %{} end, fn x, acc ->
      Map.update(acc, x, 1, fn old -> old + 1 end)
    end)
  end

  test "instrument/2 produces a valid flow" do
    have =
      ["roses are red", "violets are blue"]
      |> roses_flow()
      |> Flow.Telemetry.instrument([:roses])
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

  test "handle_event is called the expected number of times" do
    {:ok, pid} = Agent.start_link(fn -> 0 end)

    collector = fn _name, _measurement, _metadata, _config ->
      Agent.cast(pid, fn count -> count + 1 end)
    end

    get_count = fn ->
      Agent.get(pid, fn count -> count end)
    end

    event_prefix = [:red_roses]

    :telemetry.attach_many(
      "unique-identifier",
      [
        event_prefix ++ [:start],
        event_prefix ++ [:stop],
        event_prefix ++ [:exception]
      ],
      collector,
      nil
    )

    assert get_count.() == 0

    ["roses are red", "violets are blue"]
    |> roses_flow()
    |> Flow.Telemetry.instrument(event_prefix)
    |> Flow.run()

    map = 2
    reduce = 6
    expected = (map + reduce) * 2

    assert get_count.() == expected
  end
end
