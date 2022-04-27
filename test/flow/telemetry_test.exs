defmodule Flow.TelemetryTest do
  use ExUnit.Case

  alias Support.Roses

  test "instrument/2 produces a valid flow" do
    have =
      ["roses are red", "violets are blue"]
      |> Roses.flow_from_enumerable()
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
end
