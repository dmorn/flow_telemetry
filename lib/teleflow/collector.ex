defprotocol TeleFlow.Collector do
  alias TeleFlow.{StartEvent, StopEvent}
  alias TeleFlow.Collector

  @spec handle_start(Collector.t(), StartEvent.t()) :: term()
  def handle_start(collector, event)

  @spec handle_stop(Collector.t(), StopEvent.t()) :: term()
  def handle_stop(collector, event)
end
