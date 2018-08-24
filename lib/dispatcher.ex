defmodule Dispatcher do

  @monitoring_topic "MONITORING_TOPIC"

  def get_monitoring_topic do
    @monitoring_topic
  end

  defmodule Monitor do
    use GenServer

    def start_link(monitoring_topic) do
      GenServer.start(__MODULE__, monitoring_topic, [name: Dispatcher.Monitor])
    end

    def init(monitoring_topic) do
      Broker.subscribe(monitoring_topic, self())
      {:ok, []}
    end

    def handle_info({:new_child, child}, children) do
      {:noreply, [child | children]}
    end

    def handle_call(:get_children, _from, children) do
      {:reply, children, children}
    end
  end

  def start_link(%{worker_count: worker_count}) do
    pool_name = Dispatcher.Pool
    pool_config = %{ worker_module: Worker, size: worker_count }
    children = [
      %{id: Dispatcher.Monitor, start: {Monitor, :start_link, [@monitoring_topic]}},
      %{id: Dispatcher.Worker.Pool, start: {Pool, :start_link, [pool_name, pool_config]}}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def send_word(word) do
    Pool.call(Dispatcher.Pool, {:add, word})
  end

  def get_workers() do
    GenServer.call(Dispatcher.Monitor, :get_children)
  end

  def get_history() do
    Pool.call(Dispatcher.Pool, :get_history)
  end
end
