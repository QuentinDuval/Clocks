defmodule Eventually do
  @moduledoc """
  Contains eventually consistent-like assertions
  """

  def assertUntil(delay, retries, fct) do
    if retries == 1 do
      fct.()
    else
      try do
        fct.()
      rescue
        _ ->
          Process.sleep(delay)
          assertUntil(delay, retries - 1, fct)
      end
    end
  end
end
