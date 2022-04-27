defmodule Flow.Telemetry.SpanEvent do
  @moduledoc """
  Generic Telemetry Span event in the Flow context. It brings a time recording
  together with a reference to its twin event.
  """

  # It is https://www.erlang.org/doc/man/erlang.html#type-time_unit in reality
  # but I cannot use it.
  @type time_unit :: :second | :millisecond | :microsecond | :nanosecond | :native | :perf_counter
end

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
