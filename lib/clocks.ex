defmodule Clocks do
  use Application

  def start(_type, _args) do
    children = [
      %{id: PubSub, start: {PubSub, :start_link, []}},
      %{id: Dispatcher, start: {Dispatcher, :start_link, [%{worker_count: 4}]}}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
