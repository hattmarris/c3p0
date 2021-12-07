defmodule C3p0Test do
  use ExUnit.Case
  doctest C3p0

  test "greets the world" do
    assert C3p0.hello() == :world
  end
end
