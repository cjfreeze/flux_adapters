defmodule FluxAdaptersTest do
  use ExUnit.Case
  doctest FluxAdapters

  test "greets the world" do
    assert FluxAdapters.hello() == :world
  end
end
