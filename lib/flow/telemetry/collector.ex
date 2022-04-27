defprotocol Flow.Telemetry.Collector do
  alias Flow.Telemetry.{StartEvent, StopEvent}
  alias Flow.Telemetry.Collector

  @spec handle_start(Collector.t(), StartEvent.t()) :: term()
  def handle_start(collector, event)

  @spec handle_stop(Collector.t(), StopEvent.t()) :: term()
  def handle_stop(collector, event)
end
