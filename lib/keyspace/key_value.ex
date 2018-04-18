defmodule ElRedis.KeyValue do
  @moduledoc """
  A module representing a K/V pair
  """
  use GenServer, restart: :temporary
  alias ElRedis.KeySpaceSupervisor
  @null ""
  @zero 0
  @one 1
  @ok "OK"

  def start_link([key]) do
    name = via_tuple(key)
    GenServer.start_link(__MODULE__, nil, name: name)
  end

  @doc """
  Returns the tuple to pass into start_link/1 to register the key in the Registry
  """
  def via_tuple(key) do
    {:via, Registry, {:key_registry, key}}
  end

  @doc """
  Command Logic
  """

  def command(key, ["SETNX", key, value] = command) do
    if Registry.lookup(:key_registry, key) == [] do
      KeySpaceSupervisor.add_node(key)
      GenServer.call(via_tuple(key), ["SET", key, value])
      # returns 1 since key was set: RESP protocol
      @one
    else
      @zero
    end
  end

  def command(key, ["SETEX", key, time, value] = command) do
    case Registry.lookup(:key_registry, key) do
      [] ->
        KeySpaceSupervisor.add_node(key)
        command(key, command)
      [{pid, _}] ->
        GenServer.call(pid, ["SET", key, value])
        Process.send_after(pid, ["DEL", key], time * 1000)
    end
    @ok
  end

  def command(key, ["GET", key] = command) do
    if Registry.lookup(:key_registry, key) != [] do
      GenServer.call(via_tuple(key), command)
    else
      @null
    end
  end

  def command(key, ["DEL", key] = command) do
    if Registry.lookup(:key_registry, key) != [] do
      GenServer.call(via_tuple(key), command)
    else
      @zero
    end
  end

  def command(key, ["EXISTS", key] = command) do
    if Registry.lookup(:key_registry, key) == [] do
      @zero
    else
      @one
    end
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

  @doc """
  Returns 1 as reply since 1 key was deleted
  """
  def handle_call(["DEL", key], _from, value) do
    {:stop, :normal, @one,  value}
  end

  def handle_info(["DEL", key], value) do
    {:stop, :normal, value}
  end

end
