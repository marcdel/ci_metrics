defprotocol CiMetrics.Events.EventProcessor do
  def process(event)
end
