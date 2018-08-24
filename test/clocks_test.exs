defmodule ClocksTest do
  use ExUnit.Case
  doctest Clocks

  test "greets the world" do
    sentence = "hello my friend how are you"
    String.split(sentence)
      |> Enum.map(fn word -> Dispatcher.send_word(word) end)
      |> Enum.each(fn task -> Task.await(task) end)

    Eventually.assertUntil 100, 5, fn() ->
      same_history =
        Dispatcher.get_workers()
          |> Enum.map(fn w -> Worker.get_history(w) end)
          |> all_equal
    end
  end

  def all_equal([x | xs]) do
    Enum.map(xs, fn y -> y == x end)
      |> Enum.all? 
  end
end
