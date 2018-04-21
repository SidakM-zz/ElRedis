defmodule ElRedis.NodeManager do
  use GenServer
  require Logger
  alias ElRedis.RingManager
  alias ElRedis.KeyValue
  @moduledoc """
  Communicates with the K/V pairs on its Node. 
  Synchronously processes queued commands.
  """

  @command_timeout 1000000
  
  @doc """
  Server Side Methods
  """
  def start_link do
    name = RingManager.get_manager_name(Node.self)
    Logger.info("Starting Node Manager: #{inspect name}")
    GenServer.start_link(__MODULE__, %{}, name: {:global, name})
  end

  def handle_call({key, command}, from, state) do
    response = KeyValue.command(key, command)
    {:reply, response, state}
  end


  @doc """
  Client Side Methods
  """

  @doc """
  Synchronously queues the command to the appropriate node manager for the given key
  """
  def queue_command(key, command) do
    node = RingManager.get_node(key)
    GenServer.call({:global, node}, {key, command}, @command_timeout)
  end
end
