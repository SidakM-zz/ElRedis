defmodule ElRedis.StringValue do
  @moduledoc """
  A module representing a simple string K/V pair
  """
  use GenServer

  def start_link([key, value]) do
    name = via_tuple(key)
    GenServer.start_link(__MODULE__, value, name: name)
  end

  @doc """
  Registers the key in the Registry supervisor.
  """
  defp via_tuple(key) do
    {:via, Registry, {:key_registry, key}}
  end

  def command(key, command) do
    GenServer.call(via_tuple(key), command)
  end

  def handle_call(:GET, _from, value) do
    {:reply, value, value}
  end

  def handle_call({:SET, new_value}, _from, value) do
    {:reply, :ok, new_value}
  end
end
