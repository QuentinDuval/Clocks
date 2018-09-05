defmodule PubSub do
  alias Phoenix.PubSub

  def start_link() do
    import Supervisor.Spec, warn: false
    children = [
      supervisor(Phoenix.PubSub.PG2, [__MODULE__, []]),
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def broadcast(topic, message) do
    PubSub.broadcast(__MODULE__, topic, message)
  end

  def subscribe(topic, subscriber) do
    PubSub.subscribe(__MODULE__, subscriber, topic)
  end
end
