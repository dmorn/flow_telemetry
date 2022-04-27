defmodule Flow.Telemetry.Dispatcher do
  alias Flow.Telemetry.Collector
  alias Flow.Telemetry.StartEvent, as: Start
  alias Flow.Telemetry.StopEvent, as: Stop

  require Logger

  @spec attach(Collector.t(), [term()]) :: {:ok, String.t()}
  def attach(collector, event_prefix) when is_list(event_prefix) do
    id =
      [:flow, :telemetry]
      |> Enum.concat(event_prefix)
      |> Enum.join("-")

    :telemetry.attach_many(
      id,
      [
        event_prefix ++ [:start],
        event_prefix ++ [:stop],
        event_prefix ++ [:exception]
      ],
      &Flow.Telemetry.Dispatcher.handle_event/4,
      collector: collector
    )

    {:ok, id}
  end

  def handle_event(name, measurement, metadata, config) do
    step =
      name
      |> Enum.reverse()
      |> List.first()

    case step do
      step when step in [:start, :stop] ->
        collector = Keyword.get(config, :collector)
        handle_span_event(step, collector, measurement, metadata)

      _ ->
        handle_generic(name, measurement, metadata, config)
    end
  end

  defp handle_span_event(:start, collector, measurement, metadata) do
    event = Start.new(measurement, metadata)
    Collector.handle_start(collector, event)
  end

  defp handle_span_event(:stop, collector, measurement, metadata) do
    event = Stop.new(measurement, metadata)
    Collector.handle_stop(collector, event)
  end

  defp handle_generic(name, measurements, metadata, _config) do
    Logger.warn(
      message: "unexpected telemetry event received",
      module: __MODULE__,
      name: name,
      measurements: measurements,
      metadata: metadata
    )
  end
end
