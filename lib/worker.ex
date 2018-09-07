defmodule Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, [])
  end

  def get_history(self) do
    GenServer.call(self, :get_history)
  end

  @log_replication_topic "EVENT_NOTIFICATION_QUEUE"

  defmodule State do
    defstruct name: nil, clock: 0, eventLog: []
  end

  defmodule LogEntry do
    defstruct origin: nil, time: 0, event: nil
  end

  # ----------------------------------------------------------------------------

  def init(_) do
    PubSub.subscribe(@log_replication_topic, self())
    PubSub.broadcast(Dispatcher.get_monitoring_topic, {:new_child, self()})
    {:ok, %State{ name: self(), clock: 1, eventLog: [] }}
  end

  def handle_call({:add, event}, _from, worker) do
    logEntry = %LogEntry{
      origin: worker.name,
      time: worker.clock,
      event: event
    }
    newWorkerState = %{ worker |
      clock: worker.clock + 1,
      eventLog: [logEntry | worker.eventLog]
    }
    PubSub.broadcast(@log_replication_topic, {:replication_log, logEntry})
    {:reply, :ok, newWorkerState}
  end

  def handle_call(:get_history, _from, worker) do
    sortedLog = Enum.sort_by(worker.eventLog, fn event -> {event.time, event.origin} end)
    newState = %{ worker | eventLog: sortedLog }
    {:reply, sortedLog, newState}
  end

  def handle_info({:replication_log, logEntry}, worker) do
    newWorkerState =
      if logEntry.origin == worker.name do
        worker
      else
        %{ worker |
          clock: max(worker.clock, logEntry.time) + 1,
          eventLog: [logEntry | worker.eventLog] }
      end
    {:noreply, newWorkerState }
  end
end
