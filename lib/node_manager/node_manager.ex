defmodule ElRedis.NodeManager do
  use GenServer
  require Logger
  alias ElRedis.NodeDiscovery
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
    name = get_manager_name()
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
  Returns the NodeManager name given the host
  """
  def get_manager_name(host \\ Node.self) do
    Atom.to_string(host) <> ":Manager"
      |> String.to_atom
  end

  @doc """
  Synchronously queues the command to the appropriate node manager for the given key
  """
  def queue_command(key, command) do
    node = get_node(key)
    GenServer.call({:global, node}, {key, command}, @command_timeout)
  end

  @doc """
  Returns the NodeManager to call given a key. 
  Uses consistent hashing to decide what node to queue the command for.
  """
  defp get_node(key) do
    nodes = NodeDiscovery.cluster_nodes
              |> Enum.map(&(String.to_atom &1))
              |> Enum.map(&(get_manager_name(&1)))
    ring = HashRing.new()
            |> HashRing.add_nodes(nodes)
    HashRing.key_to_node(ring, key)
  end
end
