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
    GenServer.start_link(__MODULE__, %{}, name: name)
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
  def command(key, ["APPEND", key, value] = command) do
    if Registry.lookup(:key_registry, key) == [] do
      KeySpaceSupervisor.add_node(key)
      GenServer.call(via_tuple(key), ["SET", key, value])
      String.length(value)
    else
      GenServer.call(via_tuple(key), command)
    end
  end

  def command(key, ["INCRBY", key, value] = command) do
    if Registry.lookup(:key_registry, key) == [] do
      KeySpaceSupervisor.add_node(key)
      number = GenServer.call(via_tuple(key), ["SET", key, "0"])
      command(key, command)
    else
      GenServer.call(via_tuple(key), command)
    end 
  end

  def command(key, ["DECRBY", key, value] = command) do
    if Registry.lookup(:key_registry, key) == [] do
      KeySpaceSupervisor.add_node(key)
      number = GenServer.call(via_tuple(key), ["SET", key, "0"])
      command(key, command)
    else
      GenServer.call(via_tuple(key), command)
    end 
  end

  def command(key, ["STRLEN", key] = command) do
    if Registry.lookup(:key_registry, key) == [] do
      @zero
    else
      GenServer.call(via_tuple(key), command)
    end 
  end

  def command(key, ["TTL", key] = command) do
    if Registry.lookup(:key_registry, key) == [] do
      response = -2
    else
      GenServer.call(via_tuple(key), ["TTL", key])
    end
  end

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
        GenServer.call(pid, ["SETEX", key, time, value])
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

  @doc """
  State Manipulating logic
  """
  def handle_call(["GET", key], _from, state) do
    string = state[:string]
    {:reply, [string], state}
  end

  def handle_call(["SET", key, new_value], _from, state) do
    state = Map.put(state, :string, new_value)
    {:reply, "OK", state}
  end

  def handle_call(["SETEX", key, time, new_value], _from, state) do
    state = Map.put(state, :string, new_value)
    timer = Process.send_after(self(), ["DEL", key], time * 1000)
    state = Map.put(state, :timer, timer)
    {:reply, "OK", state}
  end

  def handle_call(["TTL", key], _from, state) do
    if state[:timer] do
      response = Process.read_timer(state[:timer]) / 1000
          |> round
    else
      response = -1
    end
    {:reply, response, state}
  end

  @doc """
  Appends value to end of current_value
  """
  def handle_call(["APPEND", key, new_value], _from, state) do
    current_string = state[:string]
    state = Map.put(state, :string, current_string <> new_value)
    len = String.length(state[:string])
    {:reply, len, state}
  end

  @doc """
  Increases value by increment if value can be parse as a string
  """
  def handle_call(["INCRBY", key, increment], _from, state) do
    current_string = state[:string]
    case Integer.parse(current_string) do
      {number, ""} when is_integer(number) ->
        new_num = number + increment
        state = Map.put(state, :string, Integer.to_string(new_num))
        {:reply, new_num, state}
      _ ->
        {:reply, ["Error", "Err", "value is not an integer or out of range"], state}
    end
  end

  @doc """
  Decreases value by decrement if value can be parse as a string
  """
  def handle_call(["DECRBY", key, decrement], _from, state) do
    current_string = state[:string]
    case Integer.parse(current_string) do
      {number, ""} when is_integer(number) ->
        new_num = number - decrement
        state = Map.put(state, :string, Integer.to_string(new_num))
        {:reply, new_num, state}
      _ ->
        {:reply, ["Error", "Err", "value is not an integer or out of range"], state}
    end
  end

  @doc """
  Returns length of string given key
  """
  def handle_call(["STRLEN", key], _from, state) do
    current_string = state[:string]
    len = String.length(current_string)
    {:reply, len, state}
  end

  @doc """
  Returns 1 as reply since 1 key was deleted
  """
  def handle_call(["DEL", key], _from, state) do
    {:stop, :normal, @one,  state}
  end

  @doc """
  Called when a key expires
  """
  def handle_info(["DEL", key], state) do
    {:stop, :normal, state}
  end

end
