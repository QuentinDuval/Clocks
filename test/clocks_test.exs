defmodule ClocksTest do
  use ExUnit.Case
  doctest Clocks

  test "greets the world" do
    sentence = "hello my friend how are you"
    String.split(sentence)
      |> Enum.map(fn word -> Dispatcher.send_word(word) end)
      |> Enum.each(fn task -> Task.await(task) end)
  end
end
