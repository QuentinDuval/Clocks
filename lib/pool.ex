defmodule Pool do

  def start_link(poolName, %{worker_module: worker_module, size: size}) do
    pool_config = [
      {:name, {:local, poolName}},
      {:worker_module, worker_module},
      {:size, size},
      {:max_overflow, 0}
    ]
    children = [ :poolboy.child_spec(poolName, pool_config) ]
    Supervisor.start_link(children, [strategy: :one_for_one])
  end

  def stop(this) do
    Supervisor.stop(this)
  end

  def call(poolName, message) do
    call(poolName, message, 60000)
  end

  def call(poolName, message, timeout) do
    Task.async(fn ->
      :poolboy.transaction(
        poolName,
        fn pid -> GenServer.call(pid, message) end,
        timeout)
    end)
  end
end
