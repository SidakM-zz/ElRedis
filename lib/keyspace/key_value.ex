defmodule ElRedis.KeyValue do
  @moduledoc """
  A module representing a K/V pair
  """
  use GenServer
  alias ElRedis.KeySpaceSupervisor

  def start_link([key]) do
    name = via_tuple(key)
    GenServer.start_link(__MODULE__, nil, name: name)
  end

  @doc """
  Returns the tuple to pass into start_link/1 to register the key in the Registry
  """
  defp via_tuple(key) do
    {:via, Registry, {:key_registry, key}}
  end

  def command(key, command) do
    if Registry.lookup(:key_registry, key) == [] do
      KeySpaceSupervisor.add_node(key)
    end
    GenServer.call(via_tuple(key), command)
  end

  def handle_call(["GET", key], _from, value) do
    {:reply, [value], value}
  end

  def handle_call(["SET", key, new_value], _from, value) do
    {:reply, "OK", new_value}
  end
end
