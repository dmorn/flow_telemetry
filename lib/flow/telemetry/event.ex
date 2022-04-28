defmodule Flow.Telemetry.Event.Start do
  alias Flow.Telemetry.Event.Span, as: Span
  alias Flow.Telemetry.Event.Start, as: Start

  @type t :: %Start{
          start_at: integer(),
          id: nonempty_list(),
          resolution: Span.time_unit(),
          ref: Reference.t()
        }
  defstruct [:start_at, :id, :resolution, :ref]

  def new(measurement, metadata) do
    %{system_time: start} = measurement
    %{telemetry_span_context: ref, id: id} = metadata

    %Start{
      start_at: start,
      id: id,
      resolution: :native,
      ref: ref
    }
  end

  @spec convert_time_unit(t(), Span.time_unit()) :: t()
  def convert_time_unit(start = %Start{resolution: from}, to) do
    start_at = System.convert_time_unit(start.start_at, from, to)
    %Start{start | start_at: start_at, resolution: to}
  end
end

defmodule Flow.Telemetry.Event.Stop do
  alias Flow.Telemetry.Event.Span, as: Span
  alias Flow.Telemetry.Event.Stop, as: Stop

  @type t :: %Stop{
          duration: integer(),
          resolution: Span.time_unit(),
          ref: Reference.t(),
          result_count: pos_integer()
        }
  defstruct [:duration, :resolution, :result_count, :ref]

  def new(measurement, metadata) do
    %{duration: duration} = measurement
    %{telemetry_span_context: ref, result_count: count} = metadata

    %Stop{
      duration: duration,
      resolution: :native,
      result_count: count,
      ref: ref
    }
  end

  @spec convert_time_unit(t(), Span.time_unit()) :: t()
  def convert_time_unit(stop = %Stop{resolution: from}, to) do
    duration = System.convert_time_unit(stop.duration, from, to)
    %Stop{stop | duration: duration, resolution: to}
  end
end

defmodule Flow.Telemetry.Event.Span do
  alias Flow.Telemetry.Event.Start
  alias Flow.Telemetry.Event.Stop
  alias Flow.Telemetry.Event.Span

  # It is https://www.erlang.org/doc/man/erlang.html#type-time_unit in reality
  # but I cannot use it.
  @type time_unit :: :second | :millisecond | :microsecond | :nanosecond | :native | :perf_counter

  @type t :: %Span{
          id: nonempty_list(),
          ref: Reference.t(),
          start_at: integer(),
          end_at: integer(),
          duration: integer(),
          result_count: pos_integer(),
          resolution: time_unit()
        }
  defstruct [:id, :ref, :start_at, :end_at, :duration, :result_count, :resolution]

  def new(%Start{} = start, %Stop{} = stop) do
    if start.ref != stop.ref do
      raise ArgumentError, "start and stop event references must match"
    end

    if start.resolution != stop.resolution do
      raise ArgumentError,
            "start and stop time resultions must match, have #{start.resolution} on start, #{stop.resolution} on stop"
    end

    %Span{
      id: start.id,
      ref: start.ref,
      start_at: start.start_at,
      end_at: start.start_at + stop.duration,
      duration: stop.duration,
      result_count: stop.result_count,
      resolution: start.resolution
    }
  end

  @spec convert_time_unit(t(), time_unit()) :: t()
  def convert_time_unit(span = %Span{resolution: from}, to) do
    [start_at, duration] =
      [span.start_at, span.duration]
      |> Enum.map(fn x -> System.convert_time_unit(x, from, to) end)

    end_at = start_at + duration

    %Span{span | start_at: start_at, duration: duration, end_at: end_at, resolution: to}
  end
end
