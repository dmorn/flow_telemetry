defmodule Support.MockCollector do
  alias Support.MockCollector, as: MC

  defstruct [:pid]

  def new() do
    {:ok, pid} = Agent.start_link(fn -> {[], []} end)
    %__MODULE__{pid: pid}
  end

  def put_start(%MC{pid: pid}, start) do
    Agent.cast(pid, fn {started, stopped} -> {[start | started], stopped} end)
  end

  def put_stop(%MC{pid: pid}, stop) do
    Agent.cast(pid, fn {started, stopped} -> {started, [stop | stopped]} end)
  end

  def total_events(%MC{pid: pid}) do
    Agent.get(pid, fn {started, stopped} -> Enum.count(started) + Enum.count(stopped) end)
  end
end

defimpl Flow.Telemetry.Collector, for: Support.MockCollector do
  alias Support.MockCollector, as: MC

  def handle_start(mc, start) do
    MC.put_start(mc, start)
  end

  def handle_stop(mc, stop) do
    MC.put_stop(mc, stop)
  end
end
