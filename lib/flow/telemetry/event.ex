defmodule Flow.Telemetry.StartEvent do
  alias Flow.Telemetry.SpanEvent, as: Span

  @type t :: %__MODULE__{
          start_at: integer(),
          id: nonempty_list(),
          resolution: Span.time_unit(),
          ref: Reference.t()
        }
  defstruct [:start_at, :id, :resolution, :ref]

  def new(measurement, metadata) do
    %{system_time: start} = measurement
    %{telemetry_span_context: ref, id: id} = metadata

    %__MODULE__{
      start_at: start,
      id: id,
      resolution: :native,
      ref: ref
    }
  end
end

defmodule Flow.Telemetry.StopEvent do
  alias Flow.Telemetry.SpanEvent, as: Span

  @type t :: %__MODULE__{
          duration: integer(),
          resolution: Span.time_unit(),
          ref: Reference.t(),
          result_count: pos_integer()
        }
  defstruct [:duration, :resolution, :result_count, :ref]

  def new(measurement, metadata) do
    %{duration: duration} = measurement
    %{telemetry_span_context: ref, result_count: count} = metadata

    %__MODULE__{
      duration: duration,
      resolution: :native,
      result_count: count,
      ref: ref
    }
  end
end

defmodule Flow.Telemetry.SpanEvent do
  alias Flow.Telemetry.StartEvent
  alias Flow.Telemetry.StopEvent

  # It is https://www.erlang.org/doc/man/erlang.html#type-time_unit in reality
  # but I cannot use it.
  @type time_unit :: :second | :millisecond | :microsecond | :nanosecond | :native | :perf_counter

  @type t :: %__MODULE__{
          id: nonempty_list(),
          ref: Reference.t(),
          start_at: integer(),
          end_at: integer(),
          duration: integer(),
          result_count: pos_integer(),
          resolution: time_unit()
        }
  defstruct [:id, :ref, :start_at, :end_at, :duration, :result_count, :resolution]

  def new(%StartEvent{} = start, %StopEvent{} = stop) do
    if start.ref != stop.ref do
      raise ArgumentError, "start and stop event references must match"
    end

    if start.resolution != stop.resolution do
      raise ArgumentError,
            "start and stop time resultions must match, have #{start.resolution} on start, #{stop.resolution} on stop"
    end

    %__MODULE__{
      id: start.id,
      ref: start.ref,
      start_at: start.start_at,
      end_at: start.start_at + stop.duration,
      duration: stop.duration,
      result_count: stop.result_count,
      resolution: start.resolution
    }
  end
end
