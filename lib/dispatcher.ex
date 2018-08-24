defmodule Dispatcher do

  def start_link(%{worker_count: worker_count}) do
    pool_name = Dispatcher.Pool
    pool_config = %{ worker_module: Worker, size: worker_count }
    children = [
      %{id: Dispatcher.Worker.Pool, start: {Pool, :start_link, [pool_name, pool_config]}}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def send_word(word) do
    Pool.call(Dispatcher.Pool, {:add, word})
  end

  # TODO:
  # - create a process that listen to a queue to which every process alive sends a message to (and send a "unregister" when they stop)
  # - this process is able to know every one (test consistency message)
end
