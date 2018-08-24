defmodule Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, [])
  end

  def get_history(self) do
    GenServer.call(self, :get_history) 
  end

  @event_notification_topic "EVENT_NOTIFICATION_QUEUE"

  defmodule State do
    defstruct name: nil, clock: 0, received: []
  end

  defmodule Event do
    defstruct name: nil, clock: 0, value: nil
  end

  # ----------------------------------------------------------------------------

  def init(_) do
    Broker.subscribe(@event_notification_topic, self())
    Broker.broadcast(Dispatcher.get_monitoring_topic, {:new_child, self()})
    {:ok, %State{ name: self(), clock: 1, received: [] }}
  end

  def handle_call({:add, word}, _from, state) do
    IO.puts ("ADD " <> inspect(state.name) <> " " <> word)
    event = %Event{name: state.name, clock: state.clock + 1, value: word}
    newState = %{ state |
      clock: state.clock + 1,
      received: [event | state.received]
    }
    IO.puts ("New State " <> inspect(newState))
    Broker.broadcast(@event_notification_topic, event)
    {:reply, :ok, newState}
  end

  def handle_call(:get_history, _from, state) do
    sortedReceived = Enum.sort_by(state.received, fn event -> {event.clock, event.name} end)
    newState = %{ state | received: sortedReceived }
    {:reply, sortedReceived, newState}
  end

  def handle_info(%Event{} = event, state) do
    if event.name == state.name do
      {:noreply, state}
    else
      newState = %{ state |
        clock: max(state.clock, event.clock) + 1,
        received: [event | state.received]
      }
      IO.puts ("New State " <> inspect(newState))
      {:noreply, newState }
    end
  end
end
