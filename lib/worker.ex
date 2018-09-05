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

  def handle_call({:add, event}, _from, state) do
    logEntry = %LogEntry{
      origin: state.name,
      time: state.clock + 1,
      event: event
    }
    newState = %{ state |
      clock: state.clock + 1,
      eventLog: [logEntry | state.eventLog]
    }
    PubSub.broadcast(@log_replication_topic, {:replication_log, logEntry})
    {:reply, :ok, newState}
  end

  def handle_call(:get_history, _from, state) do
    sortedLog = Enum.sort_by(state.eventLog, fn event -> {event.time, event.origin} end)
    newState = %{ state | eventLog: sortedLog }
    {:reply, sortedLog, newState}
  end

  def handle_info({:replication_log, logEntry}, state) do
    newState =
      if logEntry.origin == state.name do
        state
      else
        %{ state |
          clock: max(state.clock, logEntry.time) + 1,
          eventLog: [logEntry | state.eventLog] }
      end
    {:noreply, newState }
  end
end
