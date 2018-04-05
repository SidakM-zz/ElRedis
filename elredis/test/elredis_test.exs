defmodule ElRedisTest do
  use ExUnit.Case
  doctest ElRedis

  test "greets the world" do
    assert ElRedis.hello() == :world
  end
end
