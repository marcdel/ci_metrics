defprotocol CiMetrics.Events.EventProcessor do
  @fallback_to_any true
  def process(event)
end

defimpl CiMetrics.Events.EventProcessor, for: Any do
  require Logger

  alias CiMetrics.Events.{Deployment, DeploymentStatus, Event, EventProcessor, Push}

  def process(%Event{event_type: "push"} = event) do
    EventProcessor.process(%Push{event: event})
  end

  def process(%Event{event_type: "deployment"} = event) do
    EventProcessor.process(%Deployment{event: event})
  end

  def process(%Event{event_type: "deployment_status"} = event) do
    EventProcessor.process(%DeploymentStatus{event: event})
  end

  def process(%Event{event_type: event_type}) do
    Logger.error("Process not defined for #{event_type}")
    %{ok: [], error: []}
  end
end
